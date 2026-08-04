---
schema_version: 1
open_count: 0
waived_count: 1
fixed_count: 4
total_count: 5
last_updated: 2026-08-04T17:22:55.728Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 20 | deviation | .planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/20-07-SUMMARY.md |  | Anti-triche « vérifié par les suites de test de chaque module » constaté FAUX pour design-orchestrator/business-pilot-bundle/content-bundle/growth-bundle (0 mention de disallowedTools dans leur suite propre) — différé nommé, P-07, non corrigé | fixed |  | 2026-07-31T10:25:40.135Z | 2026-07-31T15:39:45.000Z |
| 2 | 20 | deviation | README.md |  | Compteur « N suites » des 2 README racine doit passer à 44 (pas 43 anticipé) à la release racine — voyage avec le commit de release, réservé à validation humaine post-fusion | fixed |  | 2026-07-31T10:25:47.893Z | 2026-07-31T15:32:14.394Z |
| 3 | 20 | deviation | plugin/dev-orchestrator/agents/vf-reviewer.md |  | Recette humaine différée : valider test_sim/build_sim/clean (vf-mcp-tools) contre un serveur XcodeBuildMCP vivant sur un lab iOS équipé (D-03, pas de .mcp.json dans ce repo) | waived | Recette humaine XcodeBuildMCP structurellement infermable dans ce dépôt : aucun .mcp.json, aucun projet iOS, aucun simulateur — valider test_sim/build_sim/clean exige un serveur XcodeBuildMCP vivant, donc un lab iOS équipé. vibeflow-os est le repo de distribution du plugin : la fenêtre ne peut pas y être fermée, seulement ailleurs. Dérogée en Phase 24 (ADR-066) ; à rouvrir si ce dépôt acquiert un projet iOS et un .mcp.json. | 2026-07-31T10:25:47.970Z | 2026-08-04T17:22:55.728Z |
| 4 | 20 | todo | plugin/dev-orchestrator/scripts/inject-mcp-tools.sh |  | Le gate ne valide pas qu'un nom de serveur cité dans un token vf-mcp-tools/mcp__ existe réellement — dette connue, hors périmètre des 7 critères de la phase | fixed |  | 2026-07-31T10:25:48.044Z | 2026-07-31T16:05:33.000Z |
| 5 | 21 | deviation | README.md |  | Compteur « N suites » des 2 README racine régressé à 45 (le plan 21-04 a ajouté test-check-state-integrity.sh) après la clôture de la fenêtre #2 sur 44 — CI rouge sur check-version-sync.sh, signalé par 21-VERIFICATION.md, corrigé par 21-05 dans le même commit | fixed |  | 2026-07-31T18:15:08.000Z | 2026-07-31T19:00:00.000Z |

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
  }
]
````
