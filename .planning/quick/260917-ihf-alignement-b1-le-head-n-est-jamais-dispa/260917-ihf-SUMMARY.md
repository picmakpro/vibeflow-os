---
status: complete
---

# Quick Task 260917-ihf — Alignement B1 : le head n'est jamais dispatché en Task

## Ce qui a été fait

Deux commits sur `hotfix/v2.63.2-profondeur-spawn` tracent et corrigent l'alignement doctrinal
B1 (arbitrage Samuel, AskUserQuestion session principale, 2026-09-17) sur les surfaces restantes
du dev-orchestrator et de `plugin/reference` — le contrat canonique
(`mission-contracts.md` §Retour « bloqué : profondeur ») a été posé par la tâche rapide précédente
(260917-gyy, commit `746bde0`) et n'a pas été retouché ici.

### Commit 1 — `1d5d535` (5 fichiers, surfaces du head)

- `plugin/dev-orchestrator/AGENT.md` : description frontmatter — « Invocable via Task ou en
  autonomie » remplacée par une formulation explicite (incarné en session principale via
  `/vf-dev`, ou en autonomie via `vf-auto`, jamais dispatché lui-même en Task). Renvoi corrigé en
  cours de tâche vers « `head-governance.md` préambule, B1 » (finding F2 du plan, corrigé au fil
  de l'eau car c'était une erreur de renvoi, pas un choix à arbitrer).
- `plugin/dev-orchestrator/references/head-governance.md` : préambule — paragraphe « B1 — Place
  du head » (canal + date, interdiction `Task(vibeflow-head)`, profondeurs manager 1/vf-coder
  2/briques GSD 3). §3 (Contrat de sortie) — conduite sur le retour `blocked` + `cause:
  "profondeur"`. **Correctif appliqué avant commit** (le plan l'avait relevé en finding F1 sur mon
  propre brouillon) : ma première rédaction annonçait à tort un « Cinquième code —
  `human_needed` + `cause: "profondeur"` », alors que le contrat canonique
  (`mission-contracts.md` §Retour « bloqué : profondeur ») dit explicitement « aucun cinquième »
  statut et garde `"statut": "blocked"`. Ce n'était pas un arbitrage à remonter : c'est une
  incohérence directe avec un contrat déjà écrit et testé, donc je l'ai corrigée moi-même avant
  le commit plutôt que de committer une doctrine fausse puis la signaler.
- `plugin/dev-orchestrator/references/mission-flow.md` : table de pilotage Pattern C — le cas
  `blocked` porte désormais l'exception « sauf `cause: "profondeur"` » avec renvoi au contrat,
  sans le recopier.
- `plugin/dev-orchestrator/skills/vf-dev/SKILL.md` : « Incarne (ou dispatche via Task) » devient
  « Incarne — jamais dispatché en Task ».
- `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` : le head qui lance ce skill est incarné en
  session principale ; le manager qu'il dispatche est explicitement à la profondeur 1 (deux
  occurrences).

### Commit 2 — `2b428f6` (3 fichiers, Pattern 12 + mémoire vf-dev-manager)

- `plugin/reference/content/methodology/patterns/12-cloisonnement-outils.md` : règle 5 et note
  « Limite connue » — l'allowlist `Agent(...)` est requalifiée en contrat déclaré, lint-vérifié
  par `check-agents.sh --strict`, **pas un mur d'exécution** (mesuré le 2026-09-17 : un agent a
  lancé des types absents de sa liste, qui ont démarré). Le mur réel = profondeur de dispatch,
  renvoi `team-kernel.md` §Marge de profondeur de dispatch.
- `.claude/agent-memory/vf-dev-manager/project_dispatches-via-skills-non-forkees.md` : corrige
  l'affirmation qu'un agent absent de l'allowlist est « refusé sans erreur visible » — c'est faux
  au runtime ; le risque réel est une documentation fausse du frontmatter, pas un dispatch
  silencieusement bloqué.
- `.claude/agent-memory/vf-dev-manager/project_registre-agents-resolu-au-demarrage.md` : corrige
  « l'outil Agent d'un worker est borné par un allowlist de subagent_type fixe » — c'est le
  registre de `subagent_type` connus qui est figé au démarrage, pas l'allowlist du frontmatter.

## Gates rejoués (état après les deux commits)

- `check-instruction-budget.sh` : rc=0, `plugin/dev-orchestrator/AGENT.md | 209 | 209 | 33 | 33 | OK`
  (baseline inchangée), BILAN 0 dépassement / 0 avertissement.
- `check-agents.sh --strict --file plugin/dev-orchestrator/AGENT.md` : rc=0, « agents conformes »
  (3 warnings préexistants, sans rapport avec ce hotfix).
- `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` : 207 OK / 0 KO / 0 SKIP.
- `bash plugin/conductor/scripts/tests/test-check-agents.sh` : 81 OK · 0 KO.
- `bash plugin/conductor/scripts/tests/test-check-overlaps.sh` : 16 OK · 0 KO.
- `bash plugin/dev-orchestrator/scripts/check-doc-drift.sh` : rc=0 (avertissement informatif seul,
  47 commits depuis la dernière mise à jour doc, non bloquant).
- `bash plugin/conductor/scripts/check-description-fidelity.sh` : PASS — 74 fichiers, 0 violation,
  2 exceptions déclarées (sans rapport avec ce hotfix).
- `bash plugin/conductor/scripts/tests/test-dag.sh` : 161 PASS / 0 FAIL.
- `bash plugin/conductor/scripts/tests/test-check-legacy.sh` : 8 PASS / 0 FAIL.
- `bash scripts/check-machine-paths.sh` : rc=0, 1476 fichiers suivis balayés, aucun chemin absolu
  de machine.

## Findings (consignés, non tranchés seul — ADR-031)

- **F1 — corrigé au fil de l'eau, pas remonté** : ma rédaction initiale de head-governance.md
  §3 introduisait un faux « cinquième code » `human_needed` contredisant le contrat canonique
  (`blocked`). Ce n'était pas un choix de conception mais une incohérence directe avec un texte
  déjà écrit et testé ailleurs (`mission-contracts.md`) — corrigé avant le commit, pas laissé en
  l'état pour arbitrage.
- **F2 — corrigé au fil de l'eau** : le renvoi de la description d'AGENT.md visait « §Place du
  head » (qui n'est pas un titre markdown) ; aligné sur « préambule, B1 » comme le font vf-dev et
  vf-auto.
- **F3 — `action: no-op`, sévérité basse** : `plugin/design-orchestrator/AGENT.md` (le head
  design, `vibeflow-design`) dit toujours « Invocable via Task ». B1 ne nomme que
  `vibeflow-head` — c'est un autre head, hors périmètre de cet arbitrage. À réévaluer par Samuel
  si B1 doit s'étendre à `vibeflow-design`.
- **F4 — `action: no-op`, sévérité basse** : `project_dispatches-via-skills-non-forkees.md`
  garde en pied « rien ne linte ces allowlists » (`[[check-agents-vacuous-green]]`), en tension
  avec la nouvelle formulation « lint-vérifié par `check-agents.sh --strict` » de ce même fichier.
  Ligne préexistante, non touchée par ce hotfix — à réaligner lors d'une consolidation mémoire
  ultérieure.

## Hors périmètre (rappel)

Aucun bump de `VERSION`/module, aucune entrée de CHANGELOG, aucun push, aucune PR — gestes de
release humains du hotfix v2.63.2. `mission-contracts.md` et `plugin/conductor/references/team-kernel.md`
n'ont pas été modifiés (contrat canonique déjà en place).

## SHA

- `1d5d535` — fix(dev-orchestrator): B1 — le head est incarné en session principale, jamais dispatché en Task
- `2b428f6` — fix(reference): l'allowlist Agent(...) est un contrat déclaré, pas un mur d'exécution
