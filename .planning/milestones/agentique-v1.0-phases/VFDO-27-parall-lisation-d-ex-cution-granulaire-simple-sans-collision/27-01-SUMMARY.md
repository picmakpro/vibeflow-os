---
phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision
plan: 01
subsystem: infra
tags: [dag, conductor, team-kernel, subprocess, gsd-tools, bash, python3]

# Dependency graph
requires:
  - phase: 15 (VFDO-09-*/09-CADRAGE-swarm.md, ADR-053)
    provides: "dag.sh (Pattern B) et son champ scope[] déclaratif (D-13), jamais comparé entre nœuds avant ce plan"
provides:
  - "Champ additif `stages` sur `dag.sh ready` : partition machine de la frontière en étages sans recouvrement de `scope[]`"
  - "Câblage vers `gsd-tools claude-orchestration emit-workflow` / `partitionStages()` amont, jamais réimplémenté localement (ADR-069)"
  - "Repli fail-closed (`stages: null`) prouvé en exécution réelle quand node/gsd-tools est indisponible"
  - "Doctrine d'usage de `stages` (garantie, non-garantie, dépendance dure, repli) dans mission-flow.md"
affects: ["27-02 (doctrine team-kernel.md)", "27-04 (mesure de gain, dépend de ce plan)", "tout manager du team-kernel qui lit dag.sh ready"]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 4398
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Câblage d'une capacité amont par sous-processus + manifeste temporaire fichier (jamais argv), plutôt qu'une réimplémentation locale"
    - "Contrat JSON additif (nouvelle clé, clés existantes intactes) pour préserver 5 consommateurs sans les modifier"
    - "Repli fail-closed : try/except large autour de tout le chemin sous-processus, jamais un sys.exit non nul propagé au socle"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/dag.sh
    - plugin/conductor/scripts/tests/test-dag.sh
    - plugin/dev-orchestrator/references/mission-flow.md

key-decisions:
  - "Résolution de « racine du dépôt » via os.getcwd() plutôt que `git rev-parse --show-toplevel` : évite une dépendance dure à `git` sur le PATH, cohérent avec la convention cwd-relative déjà établie par `$S` dans mission-flow.md, et testable sous PATH restreint (T29) sans dépendre de la présence de git."
  - "Exécution inline (vf-coder jouant le rôle exécuteur) plutôt que dispatch phase-wide via gsd-execute-phase : la vague 1 de cette phase contient 27-02 et 27-03, exécutés en parallèle par d'autres workers sur le même arbre de travail — un dispatch phase-wide aurait redéclenché leurs plans. Voir Deviations."
  - "STATE.md / ROADMAP.md / REQUIREMENTS.md volontairement non touchés par ce plan — responsabilité du manager (DAG de mission, dag-phase27.json), pas de ce worker, pour éviter toute collision avec les écritures concurrentes de 27-02/27-03 sur les mêmes fichiers partagés."

patterns-established:
  - "Cascade de résolution de CLI amont à 4 emplacements (env var → PATH → racine dépôt → CLAUDE_CONFIG_DIR/~/.claude), fail-closed à chaque étage — réutilisable pour tout futur câblage similaire dans dag.sh."

requirements-completed: [PAEX-05, PAEX-06]

coverage:
  - id: D1
    description: "dag.sh ready émet un champ additif stages, calculé en câblant partitionStages() amont via gsd-tools claude-orchestration emit-workflow en sous-processus, avec repli null fail-closed — ready/count restent strictement inchangés"
    requirement: "PAEX-05"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-dag.sh#T25 (recouvrement -> étages distincts)"
        status: pass
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-dag.sh#T26 (disjoint -> même étage)"
        status: pass
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-dag.sh#T27 (ready/count inchangés + déterminisme)"
        status: pass
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-dag.sh#T28 (DAG sans scope, P-02)"
        status: pass
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-dag.sh#T29 (repli CLI absente, PATH restreint réel)"
        status: pass
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-dag.sh#T30 (frontière vide -> stages=[] sans sous-processus)"
        status: pass
      - kind: other
        ref: "commande de tracer bout-en-bout de la tâche 1 (3 nœuds, 2 recouvrants -> 2 étages) rejouée à la main"
        status: pass
    human_judgment: false
  - id: D2
    description: "Suite de tests T25-T30 étendant test-dag.sh, chaque assertion neuve prouvée discriminante par mutation ciblée (retrait du court-circuit frontière-vide, résolution CLI forcée à l'échec) sur copies scratch"
    verification:
      - kind: integration
        ref: "bash plugin/conductor/scripts/tests/test-dag.sh (87 PASS / 0 FAIL, avant ce plan : 71 PASS / 0 FAIL)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Doctrine stages dans mission-flow.md (Pattern B §2) : garantie, non-garantie, dépendance dure (node/gsd-tools), repli (null vs [] jamais confondus), renvoi vers partitionStages plutôt que copie de l'algorithme (ADR-069)"
    requirement: "PAEX-06"
    verification:
      - kind: other
        ref: "grep -qF stages/partitionStages/gsd-tools plugin/dev-orchestrator/references/mission-flow.md"
        status: pass
    human_judgment: true
    rationale: "La clarté et l'exhaustivité de la doctrine pour un manager humain ne se prouvent pas par un grep de présence de chaînes — seule la présence des 3 termes attendus l'est."

# Metrics
duration: ~10min (mesuré entre le premier et le dernier commit ; exclut la phase de lecture/recherche amont non horodatée)
completed: 2026-08-05
status: complete
---

# Phase 27 Plan 01: dag.sh calcule les étages disjoints de sa frontière `ready`

**`dag.sh ready` porte désormais un champ `stages` calculé en câblant `partitionStages()` amont (gsd-tools claude-orchestration emit-workflow) — deux nœuds déclarant le même chemin dans `scope[]` ne sortent plus jamais dans le même étage dispatchable, avec repli fail-closed prouvé en exécution.**

## Performance

- **Duration:** ~10 min (entre le premier commit `8b37b69` à 23:39:51+02:00 et le dernier `5728d66` à 23:49:47+02:00 — la lecture du plan, de dag.sh, de mission-flow.md, de claude-orchestration.cjs et du RESEARCH.md en amont n'est pas horodatée séparément)
- **Started:** voir ci-dessus
- **Completed:** 2026-08-05T23:49:47+02:00
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments
- `dag.sh ready` émet `{"ready": [...], "count": N, "stages": [[...], ...] | [] | null}` — contrat strictement additif, aucun des 5 managers consommateurs n'a besoin d'être modifié
- Le calcul est **câblé**, jamais réimplémenté : un manifeste JSON temporaire (`tempfile.mkstemp`, 0600, supprimé en `finally`) est passé par chemin de fichier à `gsd-tools claude-orchestration emit-workflow --run-id dag-ready` en sous-processus, et `summary.stagesByWave[0]` est relu tel quel
- Repli fail-closed prouvé **en exécution réelle** (pas seulement en lecture de code) : sous un `PATH` restreint à `python3` seul et `GSD_TOOLS` neutralisée, `dag.sh ready` sort 0, `ready`/`count` restent intacts, `stages` vaut `null`
- 16 assertions neuves (T25-T30) portent le compteur de la suite de 71 PASS/0 FAIL à 87 PASS/0 FAIL ; chaque assertion clé a été rejouée sous mutation ciblée pour prouver qu'elle rougit réellement quand la condition testée est fausse
- `mission-flow.md` documente la capacité et ses limites (garantie, non-garantie, dépendance dure, repli) au point où `dag.sh ready` est déjà cité, avec renvoi vers `partitionStages` plutôt qu'une copie de l'algorithme

## Task Commits

Chaque tâche a été commitée atomiquement :

1. **Tâche 1 — TRACER : câblage bout-en-bout de `stages`** - `8b37b69` (feat)
2. **Tâche 2 — T25-T30 : repli, rétro-compatibilité, frontière vide** - `c776b59` (test)
3. **Tâche 3 — Doctrine `stages` dans mission-flow.md** - `5728d66` (docs)

_Aucune tâche TDD au sens RED→GREEN strict : la tâche 1 est un `type="tracer"` (implémentation + `<verify>` réel dès le premier commit), la tâche 2 étend la couverture de tests sur un comportement déjà correct (prouvé discriminant par mutation plutôt que par un cycle RED préalable)._

## Files Created/Modified
- `plugin/conductor/scripts/dag.sh` — +95/-4 : doc d'en-tête, imports (`subprocess`, `tempfile`, `shutil`), `resolve_gsd_tools_cmd()`, `build_ready_manifest()`, `compute_stages()`, action `ready` étendue
- `plugin/conductor/scripts/tests/test-dag.sh` — +88 : cas T25 à T30, en-tête étendu
- `plugin/dev-orchestrator/references/mission-flow.md` — +27 : sous-section `stages` dans Pattern B §2

## Decisions Made
- **Résolution « racine du dépôt » = `os.getcwd()`, pas `git rev-parse --show-toplevel`** : ce dépôt ne vendorise pas `gsd-core` (installé en scope user, `~/.claude/gsd-core`), et une dépendance à `git` sur le `PATH` aurait cassé le test T29 (PATH restreint) pour une raison étrangère à ce qui est testé. Cohérent avec la convention cwd-relative déjà en vigueur (`"$S"` dans mission-flow.md).
- **Frontière vide → `stages: []` calculé par court-circuit AVANT tout sous-processus**, jamais par un appel qui échouerait : `emit-workflow` rejette un `plans` vide par construction (validé en lisant `claude-orchestration.cjs`), l'appeler sur une frontière vide serait une erreur garantie plutôt qu'un résultat vide.
- **Suivre le PLAN.md plutôt que PATTERNS.md** sur la forme exacte du bloc `ready` : PATTERNS.md suggérait d'omettre la clé `stages` quand `None` (`if stages is not None: result["stages"]=stages`) ; le PLAN.md (normatif, must_haves + acceptance criteria `assert set(d) >= {"ready","count","stages"}`) exige la clé toujours présente. Suivi du PLAN.md.

## Deviations from Plan

### Déviations de processus (pas de contenu technique)

**1. [Contrainte de mandat] Exécution inline plutôt que dispatch phase-wide `gsd-execute-phase`**
- **Trouvé pendant :** avant la tâche 1, en lisant `init.execute-phase` pour la phase 27
- **Constat :** `gsd-tools query init.execute-phase "27"` liste les 6 plans de la phase (27-01 à 27-06) comme incomplets, dont 27-02 et 27-03 en vague 1 avec 27-01 — exactement les deux plans que le digest de mission signale comme exécutés EN PARALLÈLE par d'autres workers sur ce même arbre de travail. Un dispatch phase-wide (même filtré par `--wave 1`) aurait redéclenché 27-02 et 27-03.
- **Fix :** exécution du plan `27-01` uniquement, en suivant directement `execute-plan.md`/`gsd-executor.md` (le protocole que `gsd-execute-phase` aurait délégué à un subagent `gsd-executor` — agent non présent dans l'allowlist `Agent(...)` de vf-coder, cohérent avec le fait que vf-coder joue lui-même ce rôle plutôt que de le sous-déléguer).
- **Fichiers modifiés :** aucun impact sur le périmètre du plan — uniquement la manière dont l'exécution a été pilotée.
- **Vérification :** `git status --porcelain` avant/après confirme qu'aucun fichier de 27-02/27-03 n'a été touché ; leurs commits (`d708b72`, `69e1cb1`) sont apparus de façon entrelacée avec les miens, confirmant l'absence de collision.
- **Impact :** aucun sur le livrable. À signaler au manager : ce plan n'a **pas** mis à jour STATE.md, ROADMAP.md ni REQUIREMENTS.md (étapes normalement incluses dans le protocole standard d'exécuteur) — volontairement, pour ne pas écrire dans des fichiers partagés pendant que d'autres workers y écrivent concurremment. Le marquage `dag.sh mark --status=done` du nœud correspondant et toute mise à jour de ces fichiers partagés reste à la charge du manager.

---

**Total déviations :** 1 (processus, sans impact sur le contenu livré). **Impact :** aucune dérive de périmètre technique ; le manager doit prendre en charge STATE.md/ROADMAP.md/REQUIREMENTS.md pour ce plan.

## Issues Encountered
- Vérification initiale d'un décompte via `awk`/`grep` **sur le fichier source** de `test-dag.sh` au lieu de la **sortie d'exécution** de la suite (les lignes `=== T25 ... ===` sont précédées de `echo "` dans le source, donc jamais en début de ligne) — corrigé en relançant la même vérification contre `bash test-dag.sh 2>&1`, conforme à la commande exacte du plan. Sans impact sur le code livré, seulement sur ma propre vérification.
- Test manuel du repli (T29) initialement écrit avec `env -i PATH=... bash ...` depuis ce shell (zsh) : `env` cherchait `bash` via le PATH restreint fraîchement posé et échouait — corrigé en résolvant `bash` par chemin absolu (`command -v bash`) AVANT la restriction de PATH, aussi bien dans mon test manuel que dans l'assertion T29 finale.

## User Setup Required
None - aucune configuration de service externe requise.

## Next Phase Readiness
- Le champ `stages` est disponible pour 27-04 (mesure de gain), qui en dépend explicitly (`depends_on: ["27-01", "27-02", "27-03"]`).
- **Reste à faire par le manager (hors périmètre de ce plan) :** marquer le nœud DAG de mission correspondant `done` (`dag.sh mark`), et faire porter la mise à jour de STATE.md/ROADMAP.md/REQUIREMENTS.md pour ce plan — volontairement non faite ici (voir Deviations).
- `team-kernel.md` reste à la charge exclusive de 27-02 (disjonction d'écriture de la vague 1) — non touché ici, comme prévu par le plan.

---
*Phase: 27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision*
*Completed: 2026-08-05*
