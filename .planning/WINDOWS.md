---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 3
total_count: 4
last_updated: 2026-07-31T16:05:33.000Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 20 | deviation | .planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/20-07-SUMMARY.md |  | Anti-triche « vérifié par les suites de test de chaque module » constaté FAUX pour design-orchestrator/business-pilot-bundle/content-bundle/growth-bundle (0 mention de disallowedTools dans leur suite propre) — différé nommé, P-07, non corrigé | fixed |  | 2026-07-31T10:25:40.135Z | 2026-07-31T15:39:45.000Z |
| 2 | 20 | deviation | README.md |  | Compteur « N suites » des 2 README racine doit passer à 44 (pas 43 anticipé) à la release racine — voyage avec le commit de release, réservé à validation humaine post-fusion | fixed |  | 2026-07-31T10:25:47.893Z | 2026-07-31T15:32:14.394Z |
| 3 | 20 | deviation | plugin/dev-orchestrator/agents/vf-reviewer.md |  | Recette humaine différée : valider test_sim/build_sim/clean (vf-mcp-tools) contre un serveur XcodeBuildMCP vivant sur un lab iOS équipé (D-03, pas de .mcp.json dans ce repo) | open |  | 2026-07-31T10:25:47.970Z |  |
| 4 | 20 | todo | plugin/dev-orchestrator/scripts/inject-mcp-tools.sh |  | Le gate ne valide pas qu'un nom de serveur cité dans un token vf-mcp-tools/mcp__ existe réellement — dette connue, hors périmètre des 7 critères de la phase | fixed |  | 2026-07-31T10:25:48.044Z | 2026-07-31T16:05:33.000Z |

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
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-31T10:25:47.970Z",
    "resolved_at": null
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
  }
]
````
