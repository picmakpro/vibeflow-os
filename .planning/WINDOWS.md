---
schema_version: 1
open_count: 3
waived_count: 1
fixed_count: 5
total_count: 9
last_updated: 2026-09-24T08:11:36.804Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 20 | deviation | .planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/20-07-SUMMARY.md |  | Anti-triche « vérifié par les suites de test de chaque module » constaté FAUX pour design-orchestrator/business-pilot-bundle/content-bundle/growth-bundle (0 mention de disallowedTools dans leur suite propre) — différé nommé, P-07, non corrigé | fixed |  | 2026-07-31T10:25:40.135Z | 2026-07-31T15:39:45.000Z |
| 2 | 20 | deviation | README.md |  | Compteur « N suites » des 2 README racine doit passer à 44 (pas 43 anticipé) à la release racine — voyage avec le commit de release, réservé à validation humaine post-fusion | fixed |  | 2026-07-31T10:25:47.893Z | 2026-07-31T15:32:14.394Z |
| 3 | 20 | deviation | plugin/dev-orchestrator/agents/vf-reviewer.md |  | Recette humaine différée : valider test_sim/build_sim/clean (vf-mcp-tools) contre un serveur XcodeBuildMCP vivant sur un lab iOS équipé (D-03, pas de .mcp.json dans ce repo) | waived | Recette humaine XcodeBuildMCP structurellement infermable dans ce dépôt : aucun .mcp.json, aucun projet iOS, aucun simulateur — valider test_sim/build_sim/clean exige un serveur XcodeBuildMCP vivant, donc un lab iOS équipé. vibeflow-os est le repo de distribution du plugin : la fenêtre ne peut pas y être fermée, seulement ailleurs. Dérogée en Phase 24 (ADR-066) ; à rouvrir si ce dépôt acquiert un projet iOS et un .mcp.json. | 2026-07-31T10:25:47.970Z | 2026-08-04T17:22:55.728Z |
| 4 | 20 | todo | plugin/dev-orchestrator/scripts/inject-mcp-tools.sh |  | Le gate ne valide pas qu'un nom de serveur cité dans un token vf-mcp-tools/mcp__ existe réellement — dette connue, hors périmètre des 7 critères de la phase | fixed |  | 2026-07-31T10:25:48.044Z | 2026-07-31T16:05:33.000Z |
| 5 | 21 | deviation | README.md |  | Compteur « N suites » des 2 README racine régressé à 45 (le plan 21-04 a ajouté test-check-state-integrity.sh) après la clôture de la fenêtre #2 sur 44 — CI rouge sur check-version-sync.sh, signalé par 21-VERIFICATION.md, corrigé par 21-05 dans le même commit | fixed |  | 2026-07-31T18:15:08.000Z | 2026-07-31T19:00:00.000Z |
| 6 | 41 | deviation | plugin/_internal/runtime-adapter/tests/test-register-codex-agent-path-traversal.sh |  | T4 [majuscules] accepté à tort (rc=0) — rouge préexistant, reproduit à l'identique sur une extraction git archive d'origin/main (6a7b15b), hors périmètre du plan 41-01 (JSON de rulesets), jamais neutralisé ni fixé sans validation humaine (ADR-031) | open |  | 2026-09-23T12:29:52.109Z |  |
| 7 | 41 | deviation | plugin/conductor/scripts/tests/test-check-description-fidelity.sh |  | 36 KO — module Python PyYAML introuvable pour python3 (passe A) sur ce poste — rouge préexistant, reproduit à l'identique sur une extraction git archive d'origin/main (6a7b15b), hors périmètre du plan 41-01, environnement d'exécution jamais modifié sans validation humaine (ADR-031) | open |  | 2026-09-23T12:29:54.478Z |  |
| 8 | 41 | deviation | .planning/STATE.md |  | check-dev-bootstrap.sh (gate CI 'Gates workstream-aware...') rougit sur ce dépôt : le frontmatter de STATE.md dépasse la fenêtre de 60 lignes attendue par extract_frontmatter (délimiteur fermant à la ligne 61), lecture jugée illisible (D-04), assertion R1 non opposable (stdout vide des deux côtés) — rouge préexistant, reproduit à l'identique avant toute tâche du plan 41-02 (commit 5488993), hors périmètre du plan (CODEOWNERS + REQUIREMENTS.md), jamais neutralisé ni fixé sans validation humaine (ADR-031) | fixed | Cause réelle : régression de la branche feat/phase-41-volet-admin, pas de l'existant — le plan 41-01 avait porté last_activity_desc à 12 lignes, fermant le frontmatter ligne 61 (ligne 54 sur origin/main). Corrigé par l'orchestrateur le 2026-09-23 : détail déplacé dans ## Current Position, frontmatter fermé ligne 52 ; rejeu gates 14/14 vert, test-check-dev-bootstrap 35/35. | 2026-09-23T12:41:46.003Z | 2026-09-23T13:10:00.000Z |
| 9 | 41 | deviation | .planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md |  | CO-VERDICT: ECART (plan 41-06) — mergeStateStatus=CLEAN et reviewDecision vide sur PR-P/#101, PR-BASELINE/#102, PR-SENTINELLE/#103 (attendu BLOCKED/REVIEW_REQUIRED) : les deux seuls collaborateurs (samuel-neveugall, picmakpro) sont en contournement always (D-02bis), donc aucun acteur réel n'observe le refus par défaut ni la revue code owner exigée — critère 2 du ROADMAP non tenu tel que formulé. CO-DECISION: option=accepter-et-documenter (Willy, AskUserQuestion session principale, 2026-09-24). PR-BASELINE/PR-SENTINELLE fermées au pas 0 de 41-07 ; PR-P gardée pour 41-08. | open |  | 2026-09-24T08:11:36.804Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "20",
    "file": ".planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/20-07-SUMMARY.md",
    "line": null,
    "description": "Anti-triche « vérifié par les suites de test de chaque module » constaté FAUX pour design-orchestrator/business-pilot-bundle/content-bundle/growth-bundle (0 mention de disallowedTools dans leur suite propre) — différé nommé, P-07, non corrigé",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-31T10:25:40.135Z",
    "resolved_at": "2026-07-31T15:39:45.000Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "20",
    "file": "README.md",
    "line": null,
    "description": "Compteur « N suites » des 2 README racine doit passer à 44 (pas 43 anticipé) à la release racine — voyage avec le commit de release, réservé à validation humaine post-fusion",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-31T10:25:47.893Z",
    "resolved_at": "2026-07-31T15:32:14.394Z"
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "20",
    "file": "plugin/dev-orchestrator/agents/vf-reviewer.md",
    "line": null,
    "description": "Recette humaine différée : valider test_sim/build_sim/clean (vf-mcp-tools) contre un serveur XcodeBuildMCP vivant sur un lab iOS équipé (D-03, pas de .mcp.json dans ce repo)",
    "status": "waived",
    "reason": "Recette humaine XcodeBuildMCP structurellement infermable dans ce dépôt : aucun .mcp.json, aucun projet iOS, aucun simulateur — valider test_sim/build_sim/clean exige un serveur XcodeBuildMCP vivant, donc un lab iOS équipé. vibeflow-os est le repo de distribution du plugin : la fenêtre ne peut pas y être fermée, seulement ailleurs. Dérogée en Phase 24 (ADR-066) ; à rouvrir si ce dépôt acquiert un projet iOS et un .mcp.json.",
    "recorded_at": "2026-07-31T10:25:47.970Z",
    "resolved_at": "2026-08-04T17:22:55.728Z"
  },
  {
    "id": 4,
    "kind": "todo",
    "phase": "20",
    "file": "plugin/dev-orchestrator/scripts/inject-mcp-tools.sh",
    "line": null,
    "description": "Le gate ne valide pas qu'un nom de serveur cité dans un token vf-mcp-tools/mcp__ existe réellement — dette connue, hors périmètre des 7 critères de la phase",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-31T10:25:48.044Z",
    "resolved_at": "2026-07-31T16:05:33.000Z"
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "21",
    "file": "README.md",
    "line": null,
    "description": "Compteur « N suites » des 2 README racine régressé à 45 (le plan 21-04 a ajouté test-check-state-integrity.sh) après la clôture de la fenêtre #2 sur 44 — CI rouge sur check-version-sync.sh, signalé par 21-VERIFICATION.md, corrigé par 21-05 dans le même commit",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-31T18:15:08.000Z",
    "resolved_at": "2026-07-31T19:00:00.000Z"
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "41",
    "file": "plugin/_internal/runtime-adapter/tests/test-register-codex-agent-path-traversal.sh",
    "line": null,
    "description": "T4 [majuscules] accepté à tort (rc=0) — rouge préexistant, reproduit à l'identique sur une extraction git archive d'origin/main (6a7b15b), hors périmètre du plan 41-01 (JSON de rulesets), jamais neutralisé ni fixé sans validation humaine (ADR-031)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-23T12:29:52.109Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "41",
    "file": "plugin/conductor/scripts/tests/test-check-description-fidelity.sh",
    "line": null,
    "description": "36 KO — module Python PyYAML introuvable pour python3 (passe A) sur ce poste — rouge préexistant, reproduit à l'identique sur une extraction git archive d'origin/main (6a7b15b), hors périmètre du plan 41-01, environnement d'exécution jamais modifié sans validation humaine (ADR-031)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-23T12:29:54.478Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "41",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "check-dev-bootstrap.sh (gate CI 'Gates workstream-aware...') rougit sur ce dépôt : le frontmatter de STATE.md dépasse la fenêtre de 60 lignes attendue par extract_frontmatter (délimiteur fermant à la ligne 61), lecture jugée illisible (D-04), assertion R1 non opposable (stdout vide des deux côtés) — rouge préexistant, reproduit à l'identique avant toute tâche du plan 41-02 (commit 5488993), hors périmètre du plan (CODEOWNERS + REQUIREMENTS.md), jamais neutralisé ni fixé sans validation humaine (ADR-031)",
    "status": "fixed",
    "reason": "Cause réelle : régression de la branche feat/phase-41-volet-admin, pas de l'existant — le plan 41-01 avait porté last_activity_desc à 12 lignes, fermant le frontmatter ligne 61 (ligne 54 sur origin/main). Corrigé par l'orchestrateur le 2026-09-23 : détail déplacé dans ## Current Position, frontmatter fermé ligne 52 ; rejeu gates 14/14 vert, test-check-dev-bootstrap 35/35.",
    "recorded_at": "2026-09-23T12:41:46.003Z",
    "resolved_at": "2026-09-23T13:10:00.000Z",
    "milestone": null
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "41",
    "file": ".planning/workstreams/fiabilite/phases/VFDO-41-posture-de-protection-du-d-p-t/41-PREUVES.md",
    "line": null,
    "description": "CO-VERDICT: ECART (plan 41-06) — mergeStateStatus=CLEAN et reviewDecision vide sur PR-P/#101, PR-BASELINE/#102, PR-SENTINELLE/#103 (attendu BLOCKED/REVIEW_REQUIRED) : les deux seuls collaborateurs (samuel-neveugall, picmakpro) sont en contournement always (D-02bis), donc aucun acteur réel n'observe le refus par défaut ni la revue code owner exigée — critère 2 du ROADMAP non tenu tel que formulé. CO-DECISION: option=accepter-et-documenter (Willy, AskUserQuestion session principale, 2026-09-24). PR-BASELINE/PR-SENTINELLE fermées au pas 0 de 41-07 ; PR-P gardée pour 41-08.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-24T08:11:36.804Z",
    "resolved_at": null,
    "milestone": null
  }
]
````
