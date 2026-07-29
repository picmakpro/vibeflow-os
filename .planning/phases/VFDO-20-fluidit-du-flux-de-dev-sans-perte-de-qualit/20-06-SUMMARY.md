---
phase: VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualite
plan: 06
subsystem: dev-orchestrator
tags: [doctrine, dag, team-kernel, agents, revue]

requires:
  - phase: VFDO-20 (plan 20-02)
    provides: "dag.sh --scope, review_regime=full écrit par reopen, dag.sh status (fichiers gelés)"
  - phase: VFDO-20 (plan 20-03)
    provides: "vf-reviewer.md : vf-mcp-tools nommé + protocole de vérification outillée"
  - phase: VFDO-20 (plan 20-05)
    provides: ".planning/MISSION-INVARIANTS.md"
provides:
  - "mission-flow.md §Pattern E — protocole complet de l'étage revue de premier rang (pose systématique, dispatch direct, boucle de correction ciblée, gradation objective, revue de jointure sur topologie, garde-fou de comblement machine)"
  - "vf-dev-manager.md — pilote la revue en direct (revue-N), lit MISSION-INVARIANTS.md, filet de repli D-09"
  - "vf-coder.md — cycle à 3 étapes (cadrage → plan → exécution), ne dispatche plus vf-reviewer"
  - "vf-reviewer.md — dispatché UNIQUEMENT par un manager, jamais par vf-coder"
affects: [VFDO-20-plan-07]

tech-stack:
  added: []
  patterns:
    - "Généralisation d'un patron déjà écrit (promote, cf. assumption_delta_decision du plan) : mission-cross-team.md posait déjà revue-N deps=exec-N pour l'étage design croisé — Pattern E le généralise à toute mission dev sans dupliquer ni modifier le fichier source"
    - "Réécriture de règle, pas contournement : vf-dev-manager.md:108 (« Pas de double revue ») est remplacée en place par la règle inverse (nœud systématique), jamais laissée avec une exception"

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/references/mission-flow.md
    - plugin/dev-orchestrator/agents/vf-dev-manager.md
    - plugin/dev-orchestrator/agents/vf-coder.md
    - plugin/dev-orchestrator/agents/vf-reviewer.md

key-decisions:
  - "Checkpoint Task 1 (D-11, réversibilité coûteuse) : GO reçu de Samuel en amont de l'exécution (digest de mission) — non rejoué, appliqué tel que reçu, tâches 2 et 3 exécutées directement."
  - "Nouvelle section nommée « Pattern E » plutôt que de renommer le « Pattern D » existant (étages croisés) : évite de faire mentir les renvois historiques déjà écrits (CHANGELOG.md, ROADMAP.md, mission log Phase 15) qui nomment « Pattern D » — hors périmètre d'écriture de ce plan. Le Pattern D (renvoi cross-team) référence désormais aussi Pattern E dans sa liste de patterns applicables aux nœuds croisés."
  - "Filet de repli D-09 dupliqué en version courte au 2e usage d'AskUserQuestion (§Blocage) plutôt que répété intégralement, pour tenir la densité — l'explication complète vit au 1er usage (§Entrée)."

requirements-completed: [SC2, SC3, SC4, SC5]

coverage:
  - id: D-10
    description: "vf-dev-manager.md:108 (« Pas de double revue ») réécrite — remplacée par la règle de nœud revue-N systématique, pas contournée par une exception"
    requirement: "SC3"
    verification:
      - kind: unit
        ref: "grep -ci 'pas de double revue' plugin/dev-orchestrator/agents/vf-dev-manager.md → 0 ; grep -rci sur tout plugin/dev-orchestrator/ (hors .bak gitignoré) → 0"
        status: pass
    human_judgment: false
  - id: D-11
    description: "vf-coder.md : cycle à 3 étapes, plus de dispatch de vf-reviewer, plus de verdict de revue en retour ; allowlist tools: inchangée caractère pour caractère"
    requirement: "SC3"
    verification:
      - kind: unit
        ref: "sed -n '/^## Le cycle/,/^## Recherche/p' vf-coder.md | grep -cE '^[0-9]+\\. ' → 3 ; git diff vf-coder.md | grep -E '^[-+]tools:' → vide ; grep -c 'Agent(vf-reviewer' vf-coder.md → 1"
        status: pass
    human_judgment: false
  - id: D-12
    description: "4 déclencheurs objectifs énumérés (adaptateur infra, fichier partagé, code non muté, geste/géométrie) ; défaut sûr ; revue de jointure sur topologie (jamais intersection de périmètres) ; garde-fou de comblement littéral adossé à review_regime"
    requirement: "SC4"
    verification:
      - kind: other
        ref: "lecture de mission-flow.md §Pattern E §3/§4/§5 ; grep -n de la phrase littérale du garde-fou (ligne 242) ; bash dag.sh -h confirme --scope et review_regime tels que cités"
        status: pass
    human_judgment: true
    rationale: "conformité de la formulation au ROADMAP vérifiée par lecture, pas par un gate automatique dédié"
  - id: D-17
    description: "vf-dev-manager.md lit .planning/MISSION-INVARIANTS.md au même rang que l'état du projet ; format du brief/digest inchangé"
    requirement: "SC5"
    verification:
      - kind: unit
        ref: "grep -c MISSION-INVARIANTS vf-dev-manager.md → 1 ; test -f sur le chemin extrait → OK ; git diff --name-only ne liste ni mission-contracts.md ni mission-cross-team.md"
        status: pass
    human_judgment: false
  - id: D-09-closure
    description: "filet de repli sur AskUserQuestion absent au runtime en dispatch sous-agent, copié du patron déjà écrit dans vf-coder.md"
    requirement: "SC2"
    verification:
      - kind: other
        ref: "lecture des 2 emplacements (§Entrée, §Blocage) de vf-dev-manager.md"
        status: pass
    human_judgment: true
    rationale: "vérification textuelle, pas de gate machine dédié à ce filet"
  - id: densite
    description: "les 3 fichiers d'agent restent sous 250 lignes (ADR-029)"
    requirement: "SC3"
    verification:
      - kind: unit
        ref: "wc -l : vf-dev-manager.md 207, vf-coder.md 67, vf-reviewer.md 67"
        status: pass
    human_judgment: false
  - id: non-regression
    description: "43 suites test-*.sh du dépôt, 0 échec ; check-agents.sh --strict exit 0 sur le périmètre du module"
    verification:
      - kind: unit
        ref: "find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l → 43 ; bash sur chacune → 0 FAIL ; check-agents.sh --strict --agents-dir=plugin/dev-orchestrator/agents --skills-dir=plugin/dev-orchestrator/skills → exit 0 (7 warnings pré-existants, aucun nouveau lié à ce plan)"
        status: pass
    human_judgment: false
  - id: portabilite-linux
    description: "docker indisponible localement — preuve Linux différée au job CI"
    verification: []
    human_judgment: true
    rationale: "constat répété par 4 workers précédents de la phase, non re-testé ici, aucun substitut local bricolé"

duration: ~50min
completed: 2026-07-29
status: complete
---

# Phase VFDO-20 Plan 06: L'étage revue de premier rang, piloté par le manager Summary

**La revue sort du cycle interne de `vf-coder` (4 → 3 étapes) et devient un nœud de plan de bataille (`revue-N`) posé systématiquement et dispatché EN DIRECT par `vf-dev-manager`, gradé par 4 déclencheurs objectifs, doublé d'une revue de jointure déclenchée sur la topologie du DAG, et adossé au garde-fou machine `review_regime=full` écrit par `dag.sh reopen` — la règle `vf-dev-manager.md:108` qui l'interdisait est réécrite, pas contournée.**

## Performance

- **Tasks:** 3 sur 3 — Task 1 (checkpoint D-11) déjà tranchée par Samuel en amont (GO reçu dans le digest de mission), appliquée directement ; Task 2 et Task 3 exécutées telles qu'écrites.
- **Files modified:** 4

## Accomplishments

- `mission-flow.md` gagne le **Pattern E** (5 sous-sections) : pose systématique du nœud `revue-N` (deps=`exec-N`, `--scope` déclaré) ; dispatch direct + boucle de correction ciblée budgetée à 3 tours, articulée sur la même table de pilotage déterministe que le reste du contrôle de flux ; 4 déclencheurs objectifs de revue renforcée + défaut sûr (« dans le doute, revue pleine ») + abandon explicite de l'axe volume (`SEUIL_EQUIPE`) ; revue de jointure (`join-N`) déclenchée sur la TOPOLOGIE du DAG — jamais l'intersection des périmètres, vide par construction — lisant l'union des diffs ; garde-fou de comblement dans sa formulation littérale, adossé au champ machine `review_regime`.
- `mission-cross-team.md` **non modifié** (hors périmètre) : son nœud `revue-N` en est désormais explicitement une instance de Pattern E, cité comme tel dans le renvoi de `mission-flow.md` §Pattern D.
- `vf-dev-manager.md` : la règle « Pas de double revue » (ligne ~108 avant édition) est réécrite en place par la pose systématique du nœud `revue-N` piloté en direct ; liste des étages par étape restructurée (Build 3 temps sans revue / Revue en direct / Vérification Test-Audit, boucles distinctes) ; `.planning/MISSION-INVARIANTS.md` entre dans les sources de connaissance ; filet de repli D-09 (sens fermeture) ajouté aux 2 usages d'`AskUserQuestion`.
- `vf-coder.md` : cycle à 3 étapes (cadrage → plan → exécution), `description` et §Retour alignées, allowlist `tools:` intacte caractère pour caractère.
- `vf-reviewer.md` : `description`/§Mission/§Retour alignées sur le dispatch direct par le manager (jamais par `vf-coder`), renvoi vers Pattern E pour le régime et la jointure ; frontmatter (`tools:`, `disallowedTools:`, `vf-mcp-tools:`) intact.
- 43 suites `test-*.sh` du dépôt : 0 échec. `check-agents.sh --strict` sur le périmètre du module : exit 0, 7 warnings pré-existants (skills manquants, 3 noms d'agents non résolus car hors périmètre du dossier scanné) — aucun nouveau lié à ce plan.

## Task Commits

Task 1 (checkpoint:decision D-11) n'a produit aucun commit — décision déjà tranchée par Samuel avant l'exécution (option-a / GO), appliquée directement en Tasks 2 et 3.

1. **Task 2: protocole de l'étage revue + réécriture du manager** — `c342cac` (feat) — `mission-flow.md` + `vf-dev-manager.md` dans le même commit (les deux textes se répondent : le détail vit en référence, le corps du manager n'en garde que ce qu'il doit savoir).
2. **Task 3: cycle à 3 étapes + alignement des 2 workers** — `7881134` (feat) — `vf-coder.md` + `vf-reviewer.md` dans le même commit (les deux fichiers décrivent les deux faces du même circuit).

## Files Modified
- `plugin/dev-orchestrator/references/mission-flow.md` — +Pattern E (89 lignes nettes), renvoi de Pattern D mis à jour
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` — 191 → 207 lignes
- `plugin/dev-orchestrator/agents/vf-coder.md` — 66 → 67 lignes
- `plugin/dev-orchestrator/agents/vf-reviewer.md` — 64 → 67 lignes

## Decisions Made
- Nouvelle section nommée **« Pattern E »** (pas un renommage du « Pattern D » existant) : la lettre D reste attachée au renvoi cross-team pour ne pas faire mentir les 3 références historiques déjà écrites hors périmètre (`CHANGELOG.md`, `ROADMAP.md`, mission log Phase 15) qui le nomment ainsi. Pattern D référence désormais Pattern E dans sa liste de patterns applicables aux nœuds croisés, et nomme `revue-N` cross-team comme instance de Pattern E.
- Filet de repli D-09 écrit en entier au 1er usage d'`AskUserQuestion` (§Entrée), en version courte par renvoi au 2e usage (§Blocage) — tient la densité sans dupliquer le texte.

## Deviations from Plan
None — plan exécuté tel qu'écrit. Task 1 non rejouée car déjà tranchée par le donneur d'ordre (option-a/GO transmis dans le digest de mission), conformément à la consigne reçue pour cette exécution.

## Issues Encountered
- **Défaut dans la commande `<verify>` littérale de la Task 3** (bloc `awk`) : `awk '/^## Le cycle/,/^## /' vf-coder.md | grep -cE '^[0-9]+\. '` renvoie **0**, pas 3, quel que soit le contenu du fichier — la ligne d'en-tête `## Le cycle (délégation)` matche À LA FOIS le motif de début et le motif de fin de la plage `awk` (BWK awk, macOS), qui se referme donc immédiatement sur la même ligne sans jamais entrer dans la plage. Constaté par test isolé (`printf` + `awk`) reproduisant le même comportement sur un cas trivial à 2 items numérotés. Vérifié à la place avec `sed -n '/^## Le cycle/,/^## Recherche/p' vf-coder.md | grep -cE '^[0-9]+\. '` → **3**, cohérent avec la lecture manuelle du fichier (Cadrage, Plan, Exécution). Signalé pour que la commande de vérification du plan soit corrigée si réutilisée ailleurs — pas un défaut du contenu produit.

## User Setup Required
None.

## Next Phase Readiness
- Les 5 plans de la phase touchant la doctrine de revue (20-02, 20-03, 20-05, 20-06) sont maintenant cohérents entre eux : le mécanisme machine (`--scope`, `review_regime`) posé en 20-02 est CONSOMMÉ par la doctrine posée ici, l'accès MCP fin de `vf-reviewer` (20-03) et le fichier d'invariants (20-05) sont tous deux référencés depuis les textes réécrits.
- **Reste-à-faire pour 20-07** : `docs/ADR.md` ADR-060 doit acter ce déplacement de la revue en étage de premier rang, dans les mêmes termes que ce que `vf-coder.md`/`vf-dev-manager.md` disent désormais — l'ADR est écrit APRÈS, le comportement existe déjà.
- **Incohérence résiduelle à signaler, hors périmètre d'écriture de ce plan** : `mission-cross-team.md` reste correct tel quel (il posait déjà `revue-N` — rien n'y contredit la généralisation), mais il ne dit nulle part explicitement qu'il est désormais un CAS PARTICULIER de Pattern E plutôt que le seul endroit qui pose ce nœud — c'est `mission-flow.md` (Pattern E lui-même + Pattern D mis à jour) qui porte cette relation dans les deux sens. Un futur lecteur qui n'ouvrirait que `mission-cross-team.md` ne verrait pas ce renvoi. Aucune contradiction factuelle, juste une occasion de clarté non saisie ici parce que P-08 interdit d'y toucher.
- Portabilité Linux (SC7) toujours non prouvée localement (docker indisponible) — différée au job CI comme pour les plans précédents de la phase.

---
*Phase: VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit*
*Completed: 2026-07-29*
