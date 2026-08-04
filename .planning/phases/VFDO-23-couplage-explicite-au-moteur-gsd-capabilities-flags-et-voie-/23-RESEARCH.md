# Phase 23 : Couplage explicite au moteur GSD — capabilities, flags et voie unique - Research

**Researched:** 2026-08-01
**Domain:** Doctrine interne VibeFlow ↔ moteur `@opengsd/gsd-core@1.9.0` (aucune lib externe, aucun
package à installer — la « stack » de cette phase, ce sont les workflows GSD amont et les fichiers
du module `dev-orchestrator`).
**Confidence:** HIGH — quasi toutes les affirmations ci-dessous sont `[VERIFIED]` par lecture directe
des fichiers sources (installés à `$HOME/.claude/gsd-core/` et matérialisés à `$HOME/.claude/agents/`)
et du dépôt cible (`/Users/samuel/Documents/dev/vibeflow-os-p23`), pas par mémoire d'entraînement.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

31 décisions tranchées par Samuel en conversation (`23-DISCUSSION-LOG.md`), organisées en 7 zones
imposées par l'ordre du ROADMAP (sûreté d'abord). Résumé actionnable — le détail complet et les
options écartées vivent dans `23-CONTEXT.md` `<decisions>`, à lire intégralement par le planner :

- **Zone 1 — Contrat de checkpoint (Lacune 6, priorité imposée)** : D-01 champ `gate` obligatoire
  dans le bloc typé, mapping unique (`gate="blocking-human"` OU précondition non satisfaite ⇒
  `human_needed`) ; D-02 `_auto_chain_active` remis à `false` en début de mission +
  `test-dev-orchestrator.sh` échoue si `--auto` est prescrit sur `plan`/`execute` ; D-03 (**révisé**)
  le bloc typé porte le minimum de reprise (`plan_id`, type, `gate`, `Awaiting`) — PAS les 4 blocs
  complets (contrat interne executor↔execute-phase, ADR-030) ; D-04 en mission autonome,
  `gate="blocking-human"` fige le **nœud**, pas la mission ; D-04bis c'est `vf-dev-manager` (porte
  `AskUserQuestion`) qui répond aux attentes humaines, jamais `vf-coder`.
- **Zone 2 — Doctrine de flags (Lacune 3)** : D-05 `--research` gradué sur critère factuel (ADR-055
  §3) ; D-06 doctrine dans `GSD-PIPELINE.md`, renvoi croisé vers `docs-flow.md`, jamais dupliquée
  (reversibility: **costly**) ; D-07 table capabilities/hooks **GÉNÉRÉE** depuis
  `gsd-tools loop render-hooks`, patron `build-gsd-index.sh` ; D-08 **allowlist stricte** de flags
  (tout flag non nommé est fermé par défaut, y compris les futurs).
- **Zone 3 — Voie unique (Lacune 2, le trou le plus grave)** : D-09 dispatch direct de
  `gsd-planner`/`gsd-executor` **interdit sec**, une seule voie = le skill ; D-10 continuation =
  nouveau `vf-coder`, voie skill, aucune exception ; D-11 garantie machine par test sur les fichiers
  du module, discriminance prouvée par mutation ; D-12 `gsd-planner`/`gsd-executor` sortent de la
  ligne `tools:` de `vf-coder` (déclaratif, `check-agents.sh`, ADR-044) — audit complet des 20+
  entrées **différé**.
- **Zone 4 — Étages de revue et d'audit (Lacune 1)** : D-13 hook `code-review` et nœud `revue-N`
  restent disjoints, critère écrit (extension ADR-061) ; D-14 hook `secure-phase` et `vf-auditer`
  disjoints (recoupement `CONCERNS.md`) ; D-15 le bloc typé porte les verdicts déjà rendus par les
  hooks (`code-review`/nyquist/`secure`: `pass|fail|absent`) ; D-16 arbitrage en extension d'ADR-061.
- **Zone 5 — Alignement `config.json` (Lacune 5)** : D-17 gate machine générique
  `check-gsd-config.sh` (module `dev-orchestrator`), lit les clés connues depuis `gsd-core` (ne
  périme pas) ; D-18 blocs `gates`/`safety` **supprimés** (fait vérifié : 8 clés `gates.*` + 2 clés
  `safety.*` sans équivalent amont) ; D-19 toggles inscrits explicitement à valeur décidée :
  `code_review`, `pattern_mapper`, `node_repair`, `node_repair_budget`, `ui_review` — les autres
  restent au défaut amont ; D-20 gate **advisory**, contrat exit 0/3, patron `check-doc-drift.sh`,
  jamais bloquant en CI.
- **Zone 6 — Briques dormantes et tension `ship` (Lacune 4)** : D-21 ouverture de PR reste manuelle
  (ADR-059/064), `GSD-PIPELINE.md` corrigé pour dire pourquoi `gsd-ship` n'est pas emprunté ; D-22 le
  manager ne debug pas, redispatche `vf-coder` en mandat debug → skill `gsd-debug` ; D-23 quatre
  briques dormantes reçoivent un moment déclencheur (`gsd-extract-learnings`, `gsd-add-tests`,
  `gsd-spec-phase`, `gsd-undo`/`gsd-forensics`) ; D-24 table de moments déclencheurs, gabarit D-08
  Phase 22.
- **Zone 7 — Budgets de boucle additionnés (Lacune 7)** : D-25 budgets inchangés, coût **consigné** ;
  D-26 **délégué à ce RESEARCH** — voir `## D-26 : le champ de traçabilité node_repair existe-t-il
  en amont ?` ci-dessous, réponse tranchée par lecture directe ; D-27 un budget de tours **par
  ÉTAPE, partagé** entre boucle de revue et boucle de comblement ; D-28 budget épuisé ⇒ `blocked` +
  décompte complet (jamais de proposition de next step jointe).
- **Vérifications factuelles actées pendant le cadrage** : D-29 `gsd-execute-phase` sait reprendre à
  deux grains (plan via `discover_plans`, tâche via la continuation orchestrée par le skill lui-même)
  et `safe_resume_gate` protège les commits orphelins — **tout reconfirmé ci-dessous, avec les
  numéros de ligne réels de cette session** (voir écarts de citation notés en `## Écarts de
  citation`). D-30 `dag.sh` non touché (hors périmètre, module `conductor`).
- **Périmètre** : D-31 les 7 lacunes restent dans la seule Phase 23 ; le découpage se fait en
  **plans**, dans l'ordre imposé (Lacune 6 avant Lacune 3), pas en phases.

### Claude's Discretion

- Le découpage en plans et leur nombre — contraint par l'ordre imposé, pas par une préférence
  exprimée.
- La structure interne des sections ajoutées à `GSD-PIPELINE.md` et la forme exacte des tables (D-08
  allowlist, D-24 gabarit D-08 Phase 22 respectés).
- Le nom exact du script générateur de D-07 et du gate de D-17 — **D-17 fixe déjà `check-gsd-config.sh`
  dans le texte de la décision**, donc la seule vraie liberté restante est le nom du générateur D-07
  (`check-*.sh` pour un gate, patron `build-gsd-index.sh` pour un générateur).
- La forme exacte des assertions de D-02 et D-11, tant que la discriminance est prouvée par mutation.
- La formulation du critère de disjonction D-13/D-14 dans ADR-061 (3 axes : objet revu / moment du
  cycle / déclencheur).

### Deferred Ideas (OUT OF SCOPE)

- Audit complet des 20+ entrées d'allowlist `Agent(...)` de `vf-coder` (D-12 ne retire que
  `gsd-planner`/`gsd-executor`).
- Plafonner le budget global de tentatives (≈9, D-25) — à rouvrir avec des décomptes réels.
- Inventorier les 44 capabilities dans `config.json` (D-19 s'y refuse) — candidat naturel Phase 24.
- `gsd-ship`/`gsd-pr-branch` adoptés côté VibeFlow (D-21) — tant qu'ADR-059/064 tiennent.
- Toute modification de `dag.sh` (D-30, module `conductor`, transverse).
- Doctrine de flags **documentaires** — `docs-flow.md` (Phase 22) fait autorité, n'est ni modifiée ni
  dupliquée (D-06).
</user_constraints>

<phase_requirements>
## Phase Requirements

`ROADMAP.md` §Phase 23 porte `Requirements: TBD (à mapper au ledger pendant le plan)` — comme la
Phase 22 avant elle (`DOCF-01..07`, créés au plan du 2026-07-31). Aucun ID n'existe encore dans
`REQUIREMENTS.md`. Le planner doit créer un préfixe cohérent avec le ledger (motif observé :
2-4 lettres liées au thème — `DOCF` pour « doctrine documentaire »). Suggestion factuelle, non
imposée : un préfixe du type `GSDC` (« GSD Coupling ») avec un ID par zone/décision structurante.
Mapping suggéré zone → exigence potentielle (le planner tranche le découpage réel) :

| Zone | Décisions couvertes | Exigence potentielle |
|------|---------------------|----------------------|
| 1 — Checkpoint | D-01 → D-04bis | Champ `gate`, mapping `human_needed`, halt de nœud, réponse manager |
| 2 — Flags | D-05 → D-08 | Doctrine allowlist dans `GSD-PIPELINE.md`, table générée |
| 3 — Voie unique | D-09 → D-12 | Interdiction dispatch direct, continuation skill-only, gate machine |
| 4 — Revue/audit | D-13 → D-16 | Disjonction écrite (ADR-061 étendue), verdicts hooks au rapport |
| 5 — config.json | D-17 → D-20 | `check-gsd-config.sh`, suppression `gates`/`safety`, toggles décidés |
| 6 — Briques dormantes / ship | D-21 → D-24 | `GSD-PIPELINE.md` corrigé, mandat debug, table déclencheurs |
| 7 — Budgets | D-25 → D-28 | Budget partagé par étape, décompte au rapport |

Le mapping fin (quelle exigence couvre quel plan) est un livrable du **plan**, pas de cette
recherche — même patron que Phase 22 (`DOCF-01..07` créés au moment du premier plan, mappés aux 3
plans de la phase).
</phase_requirements>

## Summary

Cette phase ne touche à **aucune librairie externe** : c'est une phase de doctrine et d'outillage
interne (bash + markdown) qui aligne 9 surfaces du module `dev-orchestrator` sur le comportement
réel de `@opengsd/gsd-core@1.9.0`, installé sur cette machine (`$HOME/.claude/gsd-core/`, matérialisé
en agents/skills sous `$HOME/.claude/agents/` et `$HOME/.claude/skills/`). Le travail de recherche
consistait donc à **re-vérifier sur pièce**, dans cette session, chaque citation `fichier:ligne` que
`23-CONTEXT.md` s'appuie dessus — et à répondre à la question posée explicitement par D-26. Verdict
global : **toutes les citations tiennent**, à trois écarts près documentés ci-dessous (chemin de
fichier, pas contenu). Deux découvertes non anticipées par le cadrage sont remontées en `## Findings
non anticipés` — elles doivent être tranchées par le planner, pas supposées.

**Primary recommendation :** planifier dans l'ordre imposé par D-31 (Zone 1 → Zone 2 → Zone 3 →
{Zone 4, 5, 6, 7 en parallèle si les fichiers touchés sont disjoints), en traitant `vf-dev-manager.md`
et `mission-contracts.md` avec le plus grand soin de densité — les deux sont proches de leurs
plafonds ADR-029 (§Contrainte dimensionnante ci-dessous) et **6 des 9 surfaces de la phase les
touchent tous les deux**.

## D-26 : le champ de traçabilité `node_repair` existe-t-il en amont ? — RÉPONSE TRANCHÉE

**Question posée par le cadrage** : les artefacts de `gsd-execute-phase` (SUMMARY.md, STATE.md,
retours typés) exposent-ils le nombre de réparations `node_repair` consommées ?

**Réponse : NON — le coût amont n'est pas exposé comme un champ structuré.**

Preuve directe, lecture complète de `$HOME/.claude/gsd-core/workflows/node-repair.md`
`[VERIFIED: $HOME/.claude/gsd-core/workflows/node-repair.md:76-85]` :

```
<logging>
All repair actions must appear in SUMMARY.md under "## Deviations from Plan":

| Type | Format |
|------|--------|
| RETRY success | `[Node Repair - RETRY] Task X: [adjustment] — resolved` |
| RETRY fail → ESCALATE | `[Node Repair - RETRY] Task X: [N] attempts exhausted — escalated to user` |
| DECOMPOSE | `[Node Repair - DECOMPOSE] Task X split into [N] sub-tasks — all passed` |
| PRUNE | `[Node Repair - PRUNE] Task X skipped: [justification]` |
</logging>
```

C'est de la **prose libre** dans une section markdown, pas un champ de frontmatter compté. Confirmé
en creux par le template `$HOME/.claude/gsd-core/templates/summary-standard.md`
`[VERIFIED: $HOME/.claude/gsd-core/templates/summary-standard.md]` : le frontmatter du SUMMARY.md
porte `actuals: { tokens, tasks, commits }` mais **aucun champ `repairs`/`node_repair_count`** —
`grep -rln "node_repair"` sur tout `$HOME/.claude/gsd-core/templates/` : **zéro résultat**. Le champ
`REPAIR_BUDGET` lui-même (`workflows/execute-plan.md:341`, `[VERIFIED]`) est une variable de contexte
d'exécution passée à `node-repair.md`, jamais persistée dans un artefact relu ensuite.

**Conséquence pour le plan (D-26 appliquée)** : consigner au rapport de mission les **tours
d'équipe** (revue, comblement — ceux-là VibeFlow les pilote et les compte déjà) et **écrire
explicitement** que le nombre de réparations `node_repair` consommées en amont, à l'intérieur d'un
plan, est **invisible** sans parser la prose libre de chaque SUMMARY.md (« ## Deviations from
Plan ») — fragile (dépend d'un format texte non contractuel) et hors du périmètre décidé par D-26
(« l'exigence d'observabilité coûte que coûte » a été explicitement écartée). Ne PAS inventer un
champ agrégé côté VibeFlow qui laisserait croire à une mesure exhaustive.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Contrat de checkpoint (gate mapping) | Agent VibeFlow (`vf-coder`/`vf-dev-manager`) | Moteur GSD (`gsd-executor`, source du `gate`) | VibeFlow **relaie** un champ produit en amont, ne le calcule jamais — le moteur est la seule source de vérité du `gate`. |
| Doctrine de flags de cycle | Référence chargée on-demand (`GSD-PIPELINE.md`) | — | Fichier markdown, aucun composant runtime — chargement paresseux, coût contexte nul hors invocation. |
| Table capabilities/hooks | Script générateur (`plugin/dev-orchestrator/scripts/`) | Sortie `gsd_run loop render-hooks` (moteur) | Générée, jamais éditée à la main — même patron que `build-gsd-index.sh` → `gsd-skills-index.md`. |
| Voie unique d'invocation | Agent worker (`vf-coder`, ligne `tools:` + corps de prompt) | Gate machine (`test-dev-orchestrator.sh`) | La doctrine vit dans l'agent (déclaratif) ; la garantie vit dans le test (machine-enforced), pas l'inverse. |
| Contrat `gates`/`safety` du `config.json` | `.planning/config.json` du lab (donnée) | Gate advisory (`check-gsd-config.sh`) | Le fichier de config est une donnée de projet ; le script qui l'audite est un outil du module `dev-orchestrator`, exécutable sur N'IMPORTE QUEL lab. |
| Étages de revue/audit | Manager (`vf-dev-manager`, pose des nœuds DAG) | Hooks GSD (`code-review`, `secure-phase`, déclenchés par le moteur) | Deux étages disjoints par construction (D-13/D-14) — aucune fusion de tier, juste un critère écrit qui les distingue. |
| Budgets de boucle (node_repair vs Pattern E) | Moteur GSD (`node_repair`, interne à `execute-plan.md`) | Manager VibeFlow (Pattern E, `mission-flow.md`) | Deux objets disjoints à des granularités différentes (tâche vs étape) — jamais fusionnés (D-25). |

## Standard Stack

**N/A pour cette phase — aucune librairie externe n'est installée.** Le travail porte exclusivement
sur des fichiers `.md` (doctrine) et des scripts `.sh` (générateur, gate advisory) dans le module
`dev-orchestrator` existant. Les seules "dépendances" sont internes au dépôt (bash portable,
`gsd-tools.cjs` déjà installé, `jq` optionnel via `jqx()`).

**Installation :** aucune (`npm install` n'a rien à faire ici).

## Package Legitimacy Audit

**N/A — aucun package externe n'est installé par cette phase.** Le Package Legitimacy Gate ne
s'applique pas : tous les outils invoqués (`gsd-tools.cjs`, `git`, `bash`, `awk`) sont déjà présents
sur la machine ou dans le dépôt.

## Architecture Patterns

### System Architecture Diagram

```
Utilisateur / vibeflow-dev (routeur)
        │
        ▼
  vf-dev-manager (opus, sommet d'équipe)
        │  1. lock driver (driver-lock.sh)
        │  2. plan de bataille = DAG (dag.sh)
        │  3. dispatch frontière ready (Task)
        ▼
  vf-coder (sonnet, worker interne)
        │
        │  Cycle délégué — VOIE UNIQUE (D-09) :
        ▼
  Skill(gsd-discuss-phase --skip-research|--research)   ← D-05 : flag gradué sur FAIT
        │
        ▼
  Skill(gsd-plan-phase)          ─── JAMAIS Agent(gsd-planner) direct (D-09/D-12)
        │
        │  ── moteur insère lui-même, via capability-registry.cjs (44 caps, 12 hooks) :
        │     plan:pre  → research (gsd-phase-researcher) si workflow.research
        │              → pattern-mapper (gsd-pattern-mapper) si workflow.pattern_mapper
        │              → ui-phase, ai-integration-phase, gate ui_safety_gate
        │     plan:post → gate gap-analysis
        ▼
  Skill(gsd-execute-phase)       ─── JAMAIS Agent(gsd-executor) direct (D-09/D-12)
        │
        │  ── moteur insère lui-même :
        │     execute:post → skill code-review (si workflow.code_review)
        │     verify:post  → skill validate-phase (nyquist), secure-phase, ui-review
        │     safe_resume_gate AVANT tout dispatch (commits orphelins sans SUMMARY)
        │     checkpoint interrompu → gate="blocking-human" JAMAIS auto-approuvé,
        │        même en AUTO_CFG=true (gsd-executor.md:150, :330-332)
        ▼
  Retour typé vf-coder → vf-dev-manager
        { statut, findings[], noeuds_debloques,
          gate?, estimate?, actuals? }             ← D-01/D-03 : champs optionnels frères
        │
        │  Si human_needed / gate="blocking-human" :
        ▼
  vf-dev-manager répond (AskUserQuestion) ──── JAMAIS vf-coder (D-04bis, pas d'AskUserQuestion)
        │
        ▼
  Nœud `revue-N` (vf-reviewer, DIRECT)  ∥  Nœud `audit` (vf-auditer, DIRECT)
        │  — disjoints des hooks GSD code-review/secure-phase (D-13/D-14)
        ▼
  Rapport de mission (disque + retour compact)
```

### Recommended Project Structure

Aucun nouveau dossier — cette phase ajoute des fichiers dans la structure existante :

```
plugin/dev-orchestrator/
├── references/
│   ├── GSD-PIPELINE.md            # doctrine de flags (D-06/D-08), ligne gsd-ship corrigée (D-21)
│   └── gsd-capabilities-index.md  # NOUVEAU — nom suggéré, généré (D-07), patron gsd-skills-index.md
├── scripts/
│   ├── build-gsd-index.sh         # patron existant, à IMITER pour le nouveau générateur
│   ├── check-doc-drift.sh         # patron existant, à IMITER pour check-gsd-config.sh (exit 0/3/64)
│   ├── build-gsd-capabilities-index.sh  # NOUVEAU — nom suggéré (D-07)
│   └── check-gsd-config.sh        # NOUVEAU — nom fixé par D-17
└── scripts/tests/
    └── test-dev-orchestrator.sh   # ÉTENDU (D-02, D-11) — jamais une suite séparée
```

### Pattern 1 : Générateur idempotent, jamais édité à la main

**What :** Un script bash qui lit une source de vérité sur disque/CLI et écrit un fichier markdown
en-tête « auto-généré — NE PAS ÉDITER », idempotent (overwrite complet), surchargeable par variables
`VF_*`.

**When to use :** D-07 (table capabilities/hooks).

**Example (patron exact vérifié, `build-gsd-index.sh`) :**
```bash
# Source: /Users/samuel/Documents/dev/vibeflow-os-p23/plugin/dev-orchestrator/scripts/build-gsd-index.sh
# [VERIFIED: build-gsd-index.sh:1-30, :86-138]
SKILLS_DIR="${VF_GSD_SKILLS_DIR:-$HOME/.claude/skills}"
OUT="${VF_INDEX_OUT:-$SCRIPT_DIR/../references/gsd-skills-index.md}"
GSD_CORE_PACKAGE="${VF_GSD_CORE_PACKAGE:-@opengsd/gsd-core@1.9.0}"
# ... génère la table, puis :
{
  echo "# GSD Skills Index (auto-généré — NE PAS ÉDITER)"
  echo "> Généré le $generated_at par build-gsd-index.sh depuis $GSD_CORE_PACKAGE"
  # ...
} > "$OUT"
```

Pour D-07, la même charpente s'applique en remplaçant la source `SKILL.md` par la sortie JSON de
`node $HOME/.claude/gsd-core/bin/gsd-tools.cjs loop render-hooks <point> --raw` sur les 12 points
(liste exacte en `## 12 points de hook — sortie réelle sur ce lab` ci-dessous).

### Pattern 2 : Gate advisory, contrat exit 0/3/64

**What :** Un script bash qui **constate un fait** (jamais un jugement, ADR-055 §3), sort en 0 quand
il a quelque chose à signaler, 3 quand il n'a rien à dire, 64 sur argument invalide. Câblable en
`SessionStart`, jamais bloquant.

**When to use :** D-17/D-20 (`check-gsd-config.sh`).

**Example (patron exact vérifié, `check-doc-drift.sh`) :**
```bash
# Source: /Users/samuel/Documents/dev/vibeflow-os-p23/plugin/dev-orchestrator/scripts/check-doc-drift.sh
# [VERIFIED: check-doc-drift.sh:56-60, :145-153]
# Exit codes:
#   0  = signal émis (quelque chose à signaler)
#   3  = rien à signaler
#   64 = argument inconnu / invalide
if [ "$COUNT" -ge "$THRESHOLD" ]; then
  printf '%s\n' "[doc-drift] ${COUNT} commits de code depuis la dernière mise à jour de la doc."
  exit 0
fi
exit 3
```

Pour `check-gsd-config.sh`, le "fait" à constater est double : (a) clés **inconnues** du moteur
installé présentes dans `.planning/config.json` (aujourd'hui : `gates`, `safety` — 10 clés au total,
`[VERIFIED]` ci-dessous), et (b) toggles de cycle laissés au défaut implicite au lieu d'être écrits
(`code_review`, `pattern_mapper`, `node_repair`, `node_repair_budget`, `ui_review`). Les clés
« connues » se lisent **depuis `gsd-core`** (`bin/lib/config.cjs`, `CONFIG_DEFAULTS.workflow`), pas
en dur dans le script — sinon le gate périme à la prochaine version de `gsd-core`, exactement le
défaut que D-07 corrige pour la table de hooks.

### Anti-Patterns to Avoid

- **Dispatch direct d'un agent `gsd-*` nommé (`Agent(gsd-planner)`, `Agent(gsd-executor)`) au lieu
  du skill** : fait sauter silencieusement research, pattern-mapper, plan-checker, gap-analysis,
  drift gate, waves, verifier, code-review, nyquist et secure-phase — rien ne le signale au rapport
  typé (Lacune 2, D-09/D-12).
- **Piloter sur le type de checkpoint seul, sans le `gate`** : `checkpoints.md` nomme explicitement
  ce mode de défaillance — « *An orchestrator that dispatches on checkpoint type alone would
  auto-approve the very checkpoint the executor just refused to auto-approve* »
  `[VERIFIED: $HOME/.claude/gsd-core/references/checkpoints.md:23]`.
- **Recopier le contrat de continuation en 4 blocs côté VibeFlow** : c'est un contrat interne
  `gsd-executor` ↔ `gsd-execute-phase`, orchestré par le skill lui-même — le dupliquer viole ADR-030
  (D-03 révisée après vérification, D-29).
- **Écrire une table capabilities/hooks en dur** : périme à la première montée de version de
  `gsd-core` — c'est exactement ce qui a produit l'écart 1.8.0/1.9.0 découvert avant l'ouverture de
  cette phase.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Détecter si un checkpoint doit être auto-approuvé en mode autonome | Une logique VibeFlow qui inspecte le `type` du checkpoint | Le champ `gate` déjà produit par `gsd-executor`/`gsd-execute-phase` | Le moteur a déjà la règle exacte (règles 5/6 de `checkpoints.md`), la dupliquer c'est risquer de diverger silencieusement à la prochaine version. |
| Savoir si `gsd-execute-phase` peut reprendre un plan interrompu | Un mécanisme de reprise VibeFlow (état de tâche persistant côté module) | `discover_plans` (grain plan) + la continuation orchestrée par le skill lui-même (grain tâche) + `safe_resume_gate` (garde-fou anti-commits-orphelins) | Ces trois mécanismes existent déjà en amont et sont **plus robustes** qu'un dispatch d'agent nu — `safe_resume_gate` en particulier couvre exactement le risque que la Lacune 6(c) du ROADMAP redoutait. |
| Compter les commits de code depuis la dernière doc | Un script VibeFlow réinventé | `check-doc-drift.sh` (déjà écrit, testé, câblé en `SessionStart`) — `check-gsd-config.sh` en est le patron pour D-17 | Le contrat exit 0/3/64 est déjà éprouvé (`test-check-doc-drift.sh`), le réinventer risquerait une divergence de contrat entre deux gates du même module. |
| Vérifier qu'un agent n'a pas de dispatch nommé interdit | Un grep ad-hoc à chaque revue de code | Extension de `test-dev-orchestrator.sh` (D-11), discriminance prouvée par mutation, comme les gates existants du dépôt | Le dépôt a déjà l'historique de « gardes mortes » (`brick_routed()` en Phase 20-vintage) qui donnaient un faux vert — la mutation est la seule preuve acceptée ici. |

**Key insight :** dans ce domaine, la totalité de la logique de sûreté existe déjà en amont
(`gsd-core` 1.9.0). Le travail de cette phase n'est JAMAIS de la réimplémenter — c'est de la
**relayer fidèlement** (champs optionnels recopiés verbatim, jamais recalculés) et de fermer les
trous où VibeFlow la contourne sans le savoir.

## 12 points de hook — sortie réelle sur ce lab

Enumération exacte de `node $HOME/.claude/gsd-core/bin/lib/capability-registry.cjs`
`[VERIFIED: capability-registry.cjs, requis + inspecté ce jour]` : **44 capabilities**, **12 points
de hook**, **8 clusters** (`ai-integration`, `code-review`, `graphify`, `mempalace`, `nyquist`,
`profile-pipeline`, `security`, `ui`).

Sortie de `gsd_run loop render-hooks <point> --raw` sur les 12 points, exécutée dans cette session
sur `.planning/config.json` **actuel** de ce lab (donc AVANT nettoyage D-18/D-19 — ces résultats sont
la baseline que la phase doit faire évoluer, pas un état cible) :

| Point | `activeHooks` (capId → nature) | Toggle(s) responsable(s) |
|---|---|---|
| `discuss:pre` | *aucun* | — |
| `discuss:post` | *aucun* | — |
| `plan:pre` | `ai-integration` (step, si `ai_integration_phase`) · `research` (step, agent `gsd-phase-researcher`) · `ui` (step, si `ui_phase`) · **`pattern-mapper`** (step, agent `gsd-pattern-mapper`) · `ai-integration` (contribution API coverage) · `assumption-delta` (contribution) · `schema-gate` (contribution) · `security` (contribution threat_model) · `drift` (gate non bloquant) · `ui` (gate bloquant, `onError: halt`) | `workflow.research` (true) · `workflow.pattern_mapper` (true) · `workflow.ui_phase` (true) · `workflow.security_enforcement` (true, ce lab) |
| `plan:post` | `gap-analysis` (gate non bloquant) | `workflow.post_planning_gaps` |
| `execute:pre` | *aucun* | — |
| `execute:wave:pre` | *aucun* | — |
| `execute:wave:post` | `drift` (gate ×2 : `schema_drift_gate`) · `ui` (gate bloquant `onError: halt`) | `workflow.schema_drift_gate`, `workflow.ui_safety_gate` |
| `execute:post` | **`code-review`** (step, skill `code-review`, produit `REVIEW.md`) | `workflow.code_review` (true — défaut amont) |
| `verify:pre` | `ai-integration` (gate bloquant, `onError: halt`) | `workflow.api_coverage_gate` |
| `verify:post` | **`nyquist`** (step, skill `validate-phase`, `onError: halt`) · **`security`** (step, skill `secure-phase`, `onError: halt`) · `ui` (step, skill `ui-review`, `onError: skip`) | `workflow.nyquist_validation` (true) · `workflow.security_enforcement` (true, ce lab) · `workflow.ui_review` (**absent des défauts amont** — résolu par la capability elle-même, cf. D-19) |
| `ship:pre` | `security` (gate bloquant : `SECURITY.md.threats_open == 0`) | `workflow.security_enforcement` |
| `ship:post` | *aucun* | — |

Confirme **exactement** Constat 1 du ROADMAP (`plan:pre` porte bien `research`+`pattern-mapper`,
`execute:post` porte bien `code-review`, `verify:post` porte bien `nyquist`+`security`+`ui`) — et
montre **6 points de hook supplémentaires** que le ROADMAP n'avait pas mesurés (`plan:post`,
`execute:wave:post`, `verify:pre`, `ship:pre`, `discuss:pre/post`, `execute:pre/wave:pre` vides).
Un générateur D-07 correct doit couvrir les **12**, pas les 6 déjà cités au ROADMAP.

**Effet de bord constaté à chaque appel** : `gsd-tools: warning: unknown config key(s) in
.planning/config.json: gates, safety — these will be ignored` — preuve vivante que le nettoyage D-18
supprime un warning qui apparaît sur **CHAQUE** invocation `gsd_run` de ce lab, pas seulement en
théorie.

## Common Pitfalls

### Pitfall 1 : confondre le contrat interne executor↔execute-phase avec un contrat à porter côté VibeFlow

**What goes wrong :** recopier les 4 blocs (Completed Tasks / Current Task / Checkpoint Details /
Awaiting) dans le bloc typé `vf-coder` → `vf-dev-manager`.
**Why it happens :** le ROADMAP (Lacune 6c) le demandait littéralement, avant vérification.
**How to avoid :** D-03 (révisée) — porter seulement le minimum de reprise (`plan_id`, type,
`gate`, `Awaiting`). Le contrat en 4 blocs (`execute-plan.md:310-326`, `[VERIFIED]`) est orchestré
**par le skill `gsd-execute-phase` lui-même** (`execute-phase.md:1093-1125`, `[VERIFIED]`) — jamais
transmis à un appelant externe.
**Warning signs :** un plan qui propose de sérialiser une "table des tâches faites" dans le rapport
typé VibeFlow.

### Pitfall 2 : piloter le mode autonome sur le `type` du checkpoint, pas le `gate`

**What goes wrong :** un manager en mode autonome "continue" sur un checkpoint que l'exécuteur a
explicitement refusé de trancher (`gate="blocking-human"`), parce que le contrôle de flux VibeFlow
ne regarde que `statut` (`passed|gaps_found|human_needed|blocked`) sans savoir que `gate` existe.
**Why it happens :** le statut maison de `mission-flow.md` (Pattern C) a été conçu avant que le
contrat de `gate` amont soit documenté côté VibeFlow.
**How to avoid :** D-01 — le mapping est UNE seule règle : `gate="blocking-human"` OU précondition
non satisfaite ⇒ `human_needed`, point.
**Warning signs :** un test qui fait passer un checkpoint `gate="blocking-human"` en mode autonome
sans qu'aucune assertion n'échoue.

### Pitfall 3 : `--auto` sur `gsd-discuss-phase` persiste un état qui survit à la session

**What goes wrong :** un `--auto` isolé sur `discuss` (pas seulement sur `plan`/`execute`) écrit
`workflow._auto_chain_active: true` **dans `.planning/config.json`** — pas en mémoire de session —
puis toutes les sessions suivantes auto-tranchent `decision`/`human-verify` jusqu'à ce que quelqu'un
relance `discuss` sans `--auto`.
**Why it happens :** `discuss-phase/modes/chain.md` étape 4 `[VERIFIED: chain.md:39-43]` persiste le
flag dès que `--auto`/`--chain` est présent, indépendamment de la suite de la chaîne.
**How to avoid :** D-02 — `vf-dev-manager` remet le flag à `false` en début de mission ; le test
échoue si un fichier du module prescrit `--auto` sur `plan`/`execute`.
**Warning signs :** `.planning/config.json` d'un lab qui porte `workflow._auto_chain_active: true`
sans qu'une mission autonome ne soit en cours.

### Pitfall 4 : écrire une table de capabilities en dur au lieu de la générer

**What goes wrong :** l'index versionné affirme la version 1.8.0 alors que la machine tourne en
1.9.0 — exactement le défaut qui a déclenché l'ouverture de cette phase (Constat au ROADMAP).
**Why it happens :** un document markdown écrit à la main ne se met jamais à jour tout seul.
**How to avoid :** D-07 — la table est générée depuis `gsd_run loop render-hooks`, patron
`build-gsd-index.sh`.
**Warning signs :** un `grep` de version en dur (`1.9.0`, `1.8.0`) dans un fichier de doctrine
markdown non auto-généré.

## Code Examples

### Lire les défauts de config directement depuis `gsd-core` (jamais en dur)

```bash
# Source: [VERIFIED: $HOME/.claude/gsd-core/bin/lib/config.cjs:243-273]
# Extrait exact des défauts amont — toute doctrine/gate qui les cite doit les LIRE, pas les recopier :
workflow: {
  research: true,
  plan_check: true,
  verifier: true,
  nyquist_validation: true,
  auto_advance: false,
  node_repair: true,
  node_repair_budget: 2,
  ui_phase: true,
  ui_safety_gate: true,
  ai_integration_phase: true,
  api_coverage_gate: true,
  human_verify_mode: 'end-of-phase',
  context_guard_mode: 'warn',
  text_mode: false,
  research_before_questions: false,
  discuss_mode: 'discuss',
  skip_discuss: false,
  code_review: true,
  code_review_depth: 'standard',
  code_review_command: null,
  pattern_mapper: true,
  plan_bounce: false,
  plan_bounce_script: null,
  plan_bounce_passes: 2,
  auto_prune_state: false,
  post_planning_gaps: CONFIG_DEFAULTS.post_planning_gaps,
  security_enforcement: CONFIG_DEFAULTS.security_enforcement,
  security_asvs_level: CONFIG_DEFAULTS.security_asvs_level,
  security_block_on: CONFIG_DEFAULTS.security_block_on,
}
```

**Aucune clé `gates.*` ni `safety.*` n'existe dans ce bloc, ni ailleurs dans `config.cjs`** — vérifié
par `grep -n "gates\b\|safety\b\|confirm_plan\|always_confirm_destructive"` sur le fichier entier :
une seule occurrence, un commentaire sans rapport (`loadConfigResolved gates roo...`). Confirme
littéralement D-18 : les 10 clés que ce lab porte encore (`gates.confirm_project`,
`gates.confirm_phases`, `gates.confirm_roadmap`, `gates.confirm_breakdown`, `gates.confirm_plan`,
`gates.execute_next_plan`, `gates.issues_review`, `gates.confirm_transition`,
`safety.always_confirm_destructive`, `safety.always_confirm_external_services`) n'ont **aucune
destination** amont.

### `.planning/config.json` de ce lab — état exact au 2026-08-01

```json
// [VERIFIED: /Users/samuel/Documents/dev/vibeflow-os-p23/.planning/config.json — lu intégralement cette session]
{
  "workflow": {
    "research": true, "plan_check": true, "verifier": true, "auto_advance": false,
    "nyquist_validation": true, "security_enforcement": true, "security_asvs_level": 1,
    "security_block_on": "high", "discuss_mode": "discuss", "research_before_questions": false,
    "code_review_command": null, "plan_bounce": false, "plan_bounce_script": null,
    "plan_bounce_passes": 2, "cross_ai_execution": false, "cross_ai_command": "", "cross_ai_timeout": 300
  },
  "gates": {
    "confirm_project": true, "confirm_phases": true, "confirm_roadmap": true,
    "confirm_breakdown": true, "confirm_plan": true, "execute_next_plan": true,
    "issues_review": true, "confirm_transition": true
  },
  "safety": { "always_confirm_destructive": true, "always_confirm_external_services": true }
  // ... hooks, project_code, agent_skills, claude_md_path
}
```

**Confirmé** : `code_review`, `pattern_mapper`, `node_repair`, `node_repair_budget`, `ui_review`
sont **absents** du bloc `workflow` — ils tombent au défaut amont (`true`/`true`/`true`/`2`/absent).
C'est un choix légitime tant qu'il n'est pas écrit (D-19) — actuellement, **il ne l'est pas**.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Façade `/vf-*` (29 verbes) mappant intention → verbe → GSD | Carte d'intention unique, agent invoque les briques `gsd-*` directement | v2.33.0 (bascule agentique) | Le vocabulaire `gsd-*` est l'interface directe — GSD-PIPELINE.md:8-10 l'acte déjà, pas un changement de cette phase. |
| Index de skills figé à une version | Génération depuis le disque à chaque install/drift | Phase 1 (IDX-01/02), consolidé Phase 11 (migration `@opengsd/gsd-core`) | Patron directement réutilisable pour D-07 — rien à réinventer côté mécanique de génération. |
| `revue-N` conditionnelle ("pas de double revue") | `revue-N` posée **systématiquement**, pilotée en direct par le manager | Phase 20 (`v2.44.0`, ADR-060) | Précondition de D-13 : la revue de diff de code existe déjà comme étage de premier rang, distinct du hook `code-review` — cette phase écrit juste le critère de disjonction. |
| Un seul lock par mission | Verrou de driver + `check-branch-claim.sh` (isolation physique worktree) | Phase 21/26 (`v2.46.0`, ADR-064) | Contexte pour D-04bis/D-22 : le manager qui répond aux checkpoints/dispatche le debug le fait toujours sous le même driver-lock — pas de nouveau mécanisme de concurrence à inventer. |

**Deprecated/outdated :**
- La ligne `gsd-ship` dans le cycle canonique de `GSD-PIPELINE.md` sans explication (D-21 la corrige,
  ne la supprime pas — `gsd-ship` reste un outil réel du moteur, seulement pas emprunté ici).

## Écarts de citation — chemins réels vs cités dans CONTEXT.md/ROADMAP.md

Ces écarts portent sur le **chemin de fichier**, jamais sur le contenu cité (les citations de
contenu — numéro de ligne + texte — tiennent toutes, vérifiées ci-dessus). À corriger dans le
vocabulaire du plan pour éviter une confusion source vs installé :

1. **`agents/gsd-executor.md`** — CONTEXT.md et ROADMAP.md citent ce chemin comme relatif à
   `$HOME/.claude/gsd-core/`. **Fait vérifié cette session** : `$HOME/.claude/gsd-core/` **ne
   contient PAS** de dossier `agents/` (seulement `bin`, `contexts`, `references`, `templates`,
   `workflows`). Le fichier réel, matérialisé à l'install, vit à **`$HOME/.claude/agents/gsd-executor.md`**
   — un artefact distinct du package npm `@opengsd/gsd-core`, généré par l'installeur amont. Les
   lignes `:150` et `:330-332` citées **existent et matchent verbatim** à cet emplacement
   `[VERIFIED: $HOME/.claude/agents/gsd-executor.md:150, :330-332]` — seul le chemin de dossier
   parent diffère (`agents/` vs `gsd-core/agents/`).
2. **`plugin/conductor/conductor-references/team-kernel.md`** (canonical_refs de 23-CONTEXT.md) —
   le chemin **source** réel dans ce dépôt est **`plugin/conductor/references/team-kernel.md`**
   (sans le doublon `conductor-references/`). Le fichier lui-même précise que
   `conductor-references/` est le nom du dossier **d'installation** (`.claude/agents/conductor-references/team-kernel.md`),
   pas le chemin dans le dépôt source. La ligne 23 citée existe et matche verbatim
   `[VERIFIED: plugin/conductor/references/team-kernel.md:23]`.
3. **vf-coder.md `:32-33`** (D-09 target) — la citation ROADMAP dit `:32-33` pour les deux mentions
   « ou dispatche… » ; lecture exacte cette session : ligne **31** (« ou dispatche l'agent
   `gsd-planner` ») et ligne **32** (« ou dispatche `gsd-executor` »), pas 32-33. Décalage d'une
   ligne, sans conséquence sur la décision (les deux mentions existent et doivent disparaître).

Aucun de ces trois écarts ne remet en cause une décision de `23-CONTEXT.md` — ils affinent la
localisation exacte pour l'exécution.

## Findings non anticipés — à trancher par le planner

### Finding 1 : `vf-dev-manager.md` porte AUSSI `gsd-planner` dans sa ligne `tools:`

D-09/D-12 tranchent le retrait de `gsd-planner`/`gsd-executor` de la ligne `tools:` de **`vf-coder`**
(seul agent cité dans la décision et dans le §Deferred qui borne l'audit aux « 20+ entrées d'allowlist
`Agent(...)` de `vf-coder` »). **Fait non cité par le cadrage, découvert cette session** :

```
# [VERIFIED: plugin/dev-orchestrator/agents/vf-dev-manager.md:4]
tools: Read, Write, Bash, Glob, Grep, Skill, AskUserQuestion, Agent(vf-coder, vf-reviewer,
vf-auditer, vf-test-orchestrator, gsd-advisor-researcher, general-purpose, gsd-phase-researcher,
gsd-plan-checker, gsd-planner, gsd-pattern-mapper, gsd-doc-verifier, gsd-doc-writer,
gsd-doc-classifier, gsd-doc-synthesizer, gsd-roadmapper, gsd-integration-checker, vf-crafter,
vf-design-judge)
```

`gsd-planner` (pas `gsd-executor`) figure dans l'allowlist de `vf-dev-manager` — l'agent qui, par
doctrine (§Discipline de pilotage), « ne code, ne teste, n'audite JAMAIS lui-même ». Le corps du
prompt de `vf-dev-manager.md` ne mentionne nulle part un dispatch direct de `gsd-planner` (aucune
occurrence "dispatche gsd-planner" dans le fichier) — c'est une divergence **déclarative** entre la
ligne `tools:` et la doctrine du corps de prompt, exactement le type d'écart que D-12 corrige côté
`vf-coder`. D-09 elle-même est formulée sans qualificatif d'agent (« Le dispatch direct de
`gsd-planner` / `gsd-executor` est **interdit sec** ») — une lecture littérale de D-09 couvrirait
cette entrée ; une lecture bornée à D-12 (« ne retire que … de `vf-coder` ») ne la couvrirait pas.

**Le planner doit trancher explicitement** : soit élargir D-12 à cette occurrence précise (retrait
ponctuel, pas l'audit complet des 20+ entrées différé), soit consigner explicitement pourquoi elle
reste (ex. : `vf-dev-manager` pourrait légitimement vouloir invoquer `gsd-planner` en direct pour
une raison que la doctrine ne documente pas encore) — ne pas laisser cette divergence non traitée
par omission, ce serait reproduire exactement la Lacune 5 (piloter par omission) sur un nouveau
terrain.

### Finding 2 : `ui_review` — capability sans défaut amont, à ne pas confondre avec un défaut `false`

`[VERIFIED: capability-registry.cjs:3424, :3461, :4262, :4383, :4753]` — `workflow.ui_review` est
référencé comme condition d'activation à 5 endroits du registre de capabilities (cluster `ui`), mais
**absent** du bloc `CONFIG_DEFAULTS.workflow` de `config.cjs` (confirmé : liste exhaustive des clés
`workflow.*` par défaut ci-dessus, aucune trace de `ui_review`). Le rendu réel de `verify:post` sur
ce lab confirme : le hook `ui` (step, skill `ui-review`) est listé avec `"when": "workflow.ui_review"`
mais résolu **inactif** (absent des deux configs vues — `config.cjs` et `.planning/config.json` de
ce lab) car aucune valeur n'est écrite nulle part pour cette clé. C'est cohérent avec la note de
D-19 dans `23-CONTEXT.md` (« `ui_review` … n'est pas dans les défauts de `config.cjs` — la capability
le résout elle-même ») — confirmé exactement tel quel, pas de correction à apporter, seulement à
retranscrire fidèlement dans le script D-17/D-20 : ce toggle ne doit **jamais** être traité comme
"actuellement `false`" (une valeur qui n'existe nulle part n'est pas `false`, elle est absente).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Le préfixe d'exigence suggéré `GSDC` pour le ledger `REQUIREMENTS.md` est une proposition de cette recherche, pas une décision de Samuel | `## Phase Requirements` | Faible — le planner peut choisir tout autre préfixe cohérent avec le ledger existant (`DOCF`, `ALTI`, `VERB`…), aucune dépendance technique dessus. |
| A2 | Le nom de fichier suggéré pour le générateur D-07 (`gsd-capabilities-index.md` / `build-gsd-capabilities-index.sh`) est une proposition, pas une contrainte — D-07 laisse le nom exact à la discrétion du planner | `## Recommended Project Structure` | Faible — cosmétique, D-08/D-24 (forme des tables) sont les vraies contraintes. |

**Toutes les autres affirmations factuelles de ce document sont `[VERIFIED]`** — vérifiées par
lecture directe des fichiers sources cette session (moteur installé, dépôt cible), pas par mémoire
d'entraînement ni recherche web. Cette phase ne comporte aucune dépendance externe (librairie,
service, API) sur laquelle une hypothèse non vérifiable subsisterait.

## Open Questions

1. **`vf-dev-manager.md` doit-il perdre `gsd-planner` de sa ligne `tools:` (Finding 1) ?**
   - What we know : D-09 est formulée sans qualificatif d'agent ; D-12 et le §Deferred la bornent à
     `vf-coder` uniquement, sans mentionner `vf-dev-manager`.
   - What's unclear : si l'omission de `vf-dev-manager` dans D-12 est délibérée (le cadrage a vu
     cette ligne et l'a jugée hors périmètre) ou un angle mort du cadrage (personne n'a relu la ligne
     `tools:` de `vf-dev-manager` pendant la conversation).
   - Recommendation : trancher au plan, pas en exécution — une ligne dans le PLAN.md qui documente
     la décision explicitement (garder ou retirer), avec le fait ci-dessus en justification.

2. **Le nom exact du générateur D-07 et l'emplacement de sa sortie**
   - What we know : patron `build-gsd-index.sh` → `references/gsd-skills-index.md`, D-08/D-24
     contraignent la forme des tables, pas le nom de fichier.
   - What's unclear : rien de bloquant — pure discrétion déjà actée par `23-CONTEXT.md`.
   - Recommendation : suivre la convention `build-gsd-<sujet>.sh` → `references/gsd-<sujet>-index.md`
     pour rester cohérent avec le seul précédent existant du module.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `@opengsd/gsd-core` (installé) | Toute la phase — source de vérité des workflows amont | ✓ | 1.9.0 (`$HOME/.claude/gsd-core/VERSION`, vérifié cette session) | — |
| `gsd-tools.cjs` | `gsd_run loop render-hooks`, `config-get`/`config-set` | ✓ | Résolu à `$HOME/.claude/gsd-core/bin/gsd-tools.cjs` | — |
| `node` | Exécution de `gsd-tools.cjs` et inspection directe de `capability-registry.cjs` | ✓ | Présent (utilisé cette session) | — |
| `git` | Portabilité des scripts, `check-doc-drift.sh` patron | ✓ | Présent | — |
| `jq` | Wrapper `jqx()` (ADR-054) — optionnel, pas de dépendance dure | Non vérifié explicitement | — | Le module cible bash/awk pur pour ses propres scripts (`build-gsd-index.sh` n'utilise pas jq). |

Aucune dépendance manquante bloquante identifiée — l'environnement de ce lab est déjà celui sur
lequel toute la vérification de cette recherche a été exécutée.

## Validation Architecture

`.planning/config.json` de ce lab porte `workflow.nyquist_validation: true` — section requise.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bash + assertions maison (`ok`/`ko`/`skip`), pas de framework de test formel |
| Config file | aucun — `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (1726 lignes) est la suite unique du module |
| Quick run command | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` |
| Full suite command | Idem — pas de distinction quick/full dans ce module ; 46 suites au total dans le dépôt (`README.md` §badge, vérifié `[CITED: README.md:235]`) |

### Phase Requirements → Test Map

| Req ID (provisoire) | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| Zone 1 (checkpoint) | Mapping `gate` → `human_needed` documenté et cohérent avec `checkpoints.md` | doctrine (revue de texte, pas testable machine) | — | N/A — doctrine markdown |
| Zone 2/3 (flags, voie unique) | `--auto` jamais prescrit sur `plan`/`execute` par un fichier du module | unit (grep discriminant) | `bash .../test-dev-orchestrator.sh` (bloc à ajouter, D-02) | ❌ à écrire |
| Zone 3 (voie unique) | Aucun dispatch direct `Agent(gsd-planner)`/`Agent(gsd-executor)` en corps de prompt | unit (grep discriminant, mutation) | `bash .../test-dev-orchestrator.sh` (bloc à ajouter, D-11) | ❌ à écrire |
| Zone 5 (config.json) | `check-gsd-config.sh` détecte clés inconnues + toggles au défaut implicite | unit (fixtures config.json) | `bash check-gsd-config.sh --path <fixture>` | ❌ script + suite à écrire |
| Zone 2 (table générée) | Générateur produit une table cohérente avec `render-hooks` sur les 12 points | unit (comparaison sortie générée vs JSON `render-hooks`) | `bash build-gsd-capabilities-index.sh` (nom provisoire) | ❌ script + suite à écrire |

### Sampling Rate

- **Per task commit :** `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (suite
  complète — le module n'a pas de mode "quick", chaque commit qui touche le module doit la rejouer).
- **Per wave merge :** idem + `plugin/conductor/scripts/check-agents.sh --strict` (les surfaces D-12
  touchent la ligne `tools:` de `vf-coder`).
- **Phase gate :** suite verte + `check-agents --strict` vert sur les 6 dossiers d'agents + décompte
  « N suites » synchronisé dans les deux README (`check-version-sync.sh`) avant toute release.

### Wave 0 Gaps

- [ ] Bloc de test D-02 (`--auto` jamais sur `plan`/`execute`) dans `test-dev-orchestrator.sh`
- [ ] Bloc de test D-11 (aucun dispatch direct `gsd-planner`/`gsd-executor`, discriminance par
      mutation) dans `test-dev-orchestrator.sh`
- [ ] Suite dédiée pour `check-gsd-config.sh` (patron : `test-check-doc-drift.sh`, fixtures
      config.json avec/sans `gates`/`safety`, avec/sans toggles décidés)
- [ ] Suite ou extension pour le générateur D-07 (comparaison sortie vs `render-hooks --raw`)

## Security Domain

`.planning/config.json` de ce lab porte `workflow.security_enforcement: true`,
`security_asvs_level: 1`, `security_block_on: "high"` — section requise.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | non | aucune surface d'authentification dans cette phase (doctrine + scripts bash locaux) |
| V3 Session Management | non | idem |
| V4 Access Control | oui (limité) | l'allowlist `Agent(...)` **déclarative** (D-12) — rappel du fait déjà consigné dans le dépôt : `check-agents.sh` linte le contenu de `tools:`, mais le runtime n'applique la restriction qu'en incarnation fenêtre principale, jamais en sous-agent (`team-kernel.md:23`, `[VERIFIED]`) — ne jamais présenter D-12 comme un sandboxing runtime dans la doc produite. |
| V5 Input Validation | oui | `check-gsd-config.sh` et le générateur D-07 parsent de l'entrée (argv, JSON de `render-hooks`) — patron `check-doc-drift.sh` déjà éprouvé : validation stricte des arguments (`--threshold` non entier → 64), jamais d'`eval`, pas de shell-out non wrappé sur du contenu de fichier non maîtrisé. |
| V6 Cryptography | non | aucune donnée sensible manipulée par cette phase. |

### Known Threat Patterns for ce domaine (scripts bash + parsing JSON)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Injection shell via une valeur de config.json non maîtrisée passée à `eval`/`bash -c` | Tampering | Ne jamais `eval` une valeur lue depuis `.planning/config.json` ou la sortie `render-hooks` — parser en JSON strict (`node -e` ou `jqx()`), jamais en interpolation shell brute. Patron déjà appliqué par `check-doc-drift.sh` (`git_safe()` wrapper, `GIT_CONFIG_NOSYSTEM=1`). |
| Argument non validé → comportement indéterminé (`--threshold` vide/négatif) | Tampering | Validation stricte avant toute logique, exit 64 sur invalide — patron `check-doc-drift.sh:69-102`, à reprendre à l'identique dans `check-gsd-config.sh`. |
| Génération de table depuis une sortie `render-hooks` non fiabilisée (fragment de prompt injecté tel quel dans un markdown versionné) | Tampering / Information Disclosure | Le champ `rendered`/`fragment.inline` de `render-hooks --raw` contient de la prose destinée à un LLM, pas forcément du markdown sûr pour un document versionné — le générateur D-07 doit extraire les métadonnées structurées (`capId`, `kind`, `when`, `onError`) et NE PAS recopier `fragment.inline` verbatim dans la table publiée (ce champ est volumineux — voir la sortie `plan:pre` capturée cette session, plusieurs Ko de prose par capability). |

## Sources

### Primary (HIGH confidence — lu directement cette session)

- `$HOME/.claude/gsd-core/references/checkpoints.md` (826 lignes) — contrat de checkpoint, règles 5/6, `gate="blocking-human"`.
- `$HOME/.claude/gsd-core/workflows/execute-phase.md` (1645 lignes) — `safe_resume_gate` (:178-192), continuation (:1093-1125), `verify:post`/`execute:post` (:1152/:1210), `discover_plans` (:1642).
- `$HOME/.claude/gsd-core/workflows/execute-plan.md` (558 lignes) — contrat 4 blocs (:310-326), budgets `node_repair` (:330-345).
- `$HOME/.claude/gsd-core/workflows/plan-phase.md` (1662 lignes) — prompt recherche (:333), auto-advance (:1540-1577).
- `$HOME/.claude/gsd-core/workflows/discuss-phase/modes/chain.md` (98 lignes) — persistance `_auto_chain_active` (étapes 2/4/5).
- `$HOME/.claude/gsd-core/workflows/node-repair.md` (93 lignes) — logging prose-only, pas de champ structuré.
- `$HOME/.claude/gsd-core/bin/lib/config.cjs` (1134 lignes) — défauts `workflow.*` (:243-273), absence totale de `gates.*`/`safety.*`.
- `$HOME/.claude/gsd-core/bin/lib/capability-registry.cjs` (7096 lignes) — 44 capabilities, 12 hook points, 8 clusters, `ui_review`.
- `$HOME/.claude/agents/gsd-executor.md` (matérialisé, pas dans `gsd-core/`) — préconditions (:150), auto-mode checkpoint (:328-332).
- `$HOME/.claude/gsd-core/templates/summary-standard.md` — frontmatter `actuals`, absence de champ `repairs`.
- Sortie live `node $HOME/.claude/gsd-core/bin/gsd-tools.cjs loop render-hooks <point> --raw` sur les 12 points, exécutée sur ce lab cette session.
- `/Users/samuel/Documents/dev/vibeflow-os-p23/.planning/config.json` — lu intégralement cette session.
- `plugin/dev-orchestrator/references/GSD-PIPELINE.md`, `mission-contracts.md` (258 lignes, 16.4K), `mission-flow.md` (263 lignes), `docs-flow.md` (111 lignes) — lus intégralement.
- `plugin/dev-orchestrator/agents/vf-coder.md` (74/75 lignes), `vf-dev-manager.md` (236/237 lignes) — lus intégralement.
- `plugin/dev-orchestrator/scripts/build-gsd-index.sh` (138 lignes), `check-doc-drift.sh` (153 lignes) — lus intégralement, patrons D-07/D-17.
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (1726 lignes) — régions T3/T4 (:762-882), T6 install e2e (:912-935), T14 exhaustivité (:1124-1210).
- `plugin/conductor/references/team-kernel.md` (chemin source réel, distinct du chemin d'install cité en canonical_refs) — ligne 23, allowlist = contrat documenté.
- `plugin/conductor/scripts/check-agents.sh` (653 lignes) — contrat `--strict`, `--third-party-prefix`.
- `.planning/codebase/CONVENTIONS.md` §Portabilité bash (ADR-054) — `jqx()`, pas de `sed -i` nu, pas de `grep -P`, préfixe `VF_`.
- `.planning/ROADMAP.md` §Phase 23 (lignes 1174-1318) — texte intégral des 7 lacunes, recoupé mot pour mot avec `23-CONTEXT.md`.

### Secondary (MEDIUM confidence)

- `README.md`/`README.fr.md` (changelog v2.44.0-v2.46.0) — contexte de fraîcheur du dépôt (46 suites, ADR-060/061/064) au moment de la recherche, non contraignant pour le plan.

### Tertiary (LOW confidence)

- Aucune — cette recherche n'a mobilisé aucune source web ni mémoire d'entraînement non vérifiée ;
  le domaine est 100% interne (dépôt + moteur installé localement).

## Metadata

**Confidence breakdown :**
- Contrat de checkpoint / voie unique / budgets (Zones 1, 3, 7) : **HIGH** — chaque citation
  `fichier:ligne` de `23-CONTEXT.md` a été rouverte et confrontée au texte exact cette session.
- Table de hooks / capabilities (Zone 2) : **HIGH** — sortie live exécutée sur ce lab, pas déduite.
- `config.json` (Zone 5) : **HIGH** — fichier lu intégralement, warning reproduit en direct.
- Densité ADR-029 (`vf-dev-manager.md`, `mission-contracts.md`) : **HIGH** — `wc -l`/`wc -c` exécutés
  cette session, pas des estimations.
- Findings 1 et 2 (§Findings non anticipés) : **MEDIUM** — faits vérifiés, mais l'arbitrage
  (que faire de ces faits) n'a pas été tranché par Samuel — à porter explicitement au plan.

**Research date :** 2026-08-01
**Valid until :** jusqu'à la prochaine montée de version de `@opengsd/gsd-core` (actuellement 1.9.0)
— toute table/valeur citée ici qui n'est PAS générée dynamiquement (D-07/D-17) devra être re-vérifiée
si la machine passe à 1.10.0+. Les patterns de code (générateur, gate advisory) restent valides
indépendamment de la version.
