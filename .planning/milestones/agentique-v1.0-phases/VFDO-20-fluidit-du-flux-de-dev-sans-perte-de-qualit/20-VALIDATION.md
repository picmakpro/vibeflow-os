---
phase: 20
slug: fluidit-du-flux-de-dev-sans-perte-de-qualit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-29
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash pur, zéro dépendance — helpers `ok()`/`ko()` maison |
| **Config file** | Aucun (chaque `test-*.sh` est un exécutable autonome) |
| **Quick run command** | `bash plugin/conductor/scripts/tests/test-dag.sh` (ou la suite ciblée par le changement en cours) |
| **Full suite command** | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort \| while IFS= read -r t; do bash "$t"; done` |
| **Estimated runtime** | ~quelques secondes par suite, quelques dizaines de secondes pour la boucle complète (37+ suites) |

---

## Sampling Rate

- **After every task commit:** Run la suite ciblée par le fichier touché (ex. `test-dag.sh` après un edit de `dag.sh`, `test-inject-mcp-tools.sh` après un edit de `inject-mcp-tools.sh`).
- **After every plan wave:** `find plugin scripts -type f -path '*/tests/test-*.sh' | sort | while IFS= read -r t; do bash "$t"; done` (la boucle exacte de la CI).
- **Before `/gsd-verify-work`:** Full suite verte + `check-agents.sh --strict` sur les 6 dossiers d'agents + `check-version-sync.sh` + `check-release-tag.sh --remote`.
- **Max feedback latency:** ~60s (durée de la boucle complète des suites bash).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-XX-01 | TBD | 1 | SC1 | V4 | `vf-reviewer` reçoit l'accès MCP fin sans polluer `vf-coder`/mobile-test | unit | `bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` | ✅ suite existante (10 cas) — étendre avec le mode nommé | ⬜ pending |
| 20-XX-02 | TBD | 1 | SC1 | V5 | Regex charset accepte `mcp__X__*` mais rejette `mcp__X__*Y` | unit | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ✅ existant — ajouter cas D-22 | ⬜ pending |
| 20-XX-03 | TBD | 1 | SC2 | V4 | `disallowedTools: Write, Edit` accepté par le gate sans changement | unit | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ✅ existant (KNOWN déjà couvert), pas de nouveau cas requis | ⬜ pending |
| 20-XX-04 | TBD | — | SC3/SC4 | V3 (analogie) | `dag.sh add --scope=...` accepté, rétro-compat sur nœuds sans scope | unit | `bash plugin/conductor/scripts/tests/test-dag.sh` | ❌ Wave 0 — ajouter cas `--scope` | ⬜ pending |
| 20-XX-05 | TBD | — | SC4 | V4 | `dag.sh reopen` force `review_regime: full` sur nœuds `revue-*`/`join` | unit | `bash plugin/conductor/scripts/tests/test-dag.sh` | ❌ Wave 0 — ajouter cas reopen+regime | ⬜ pending |
| 20-XX-06 | TBD | — | SC5 | — | Script de zone morte détecte un glob qui ne matche plus rien | unit (nouveau script) | `bash plugin/<module>/scripts/tests/test-check-mission-invariants.sh` | ❌ Wave 0 — nouveau fichier, patron `test-check-doc-drift.sh` | ⬜ pending |
| 20-XX-07 | TBD | — | SC6 | V4 (Repudiation) | Scope par défaut (sans `--agents-dir`) exercé et vert | unit | `bash plugin/conductor/scripts/tests/test-check-agents.sh` + `test-check-debug-research.sh` | ❌ Wave 0 — cas manquant (D-24, obligatoire, non négociable) | ⬜ pending |
| 20-XX-08 | TBD | — | SC6 | V4 (Repudiation) | `--hook` silencieux à 0 warning, imprime si > 0 | unit | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ❌ Wave 0 — cas D-21 manquant | ⬜ pending |
| 20-XX-09 | TBD | — | SC6 | — | `--third-party-prefix` sur `check-debug-research.sh` filtre correctement | unit | `bash plugin/conductor/scripts/tests/test-check-debug-research.sh` | ❌ Wave 0 — cas manquant (mécanisme n'existe pas encore sur ce script) | ⬜ pending |
| 20-XX-10 | TBD | final | SC7 | — | `check-agents.sh --strict` vert sur les 6 dossiers d'agents après tous les changements | gate CI | `check-agents.sh --strict --agents-dir=<d>` (job `gates`, déjà câblé) | ✅ CI existante | ⬜ pending |
| 20-XX-11 | TBD | final | SC7 | — | Portabilité macOS + Linux prouvée par exécution | CI | job `tests` (`ubuntu-latest`) + exécution locale macOS | ✅ CI existante — aucune nouveauté requise | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Les Task ID exacts et le découpage en plans/waves sont fixés par `gsd-planner` — cette carte fait le pont Requirement → Test, à recopier telle quelle dans les PLAN.md correspondants.*

---

## Wave 0 Requirements

- [ ] `plugin/conductor/scripts/tests/test-check-agents.sh` — cas « défaut sans `--agents-dir` » (D-24, non négociable) + cas regex `*` final (D-22) + cas warnings conditionnels en `--hook` (D-21).
- [ ] `plugin/conductor/scripts/tests/test-check-debug-research.sh` — même cas « défaut sans `--agents-dir` » (D-24) + cas `--third-party-prefix` (mécanisme nouveau sur ce script, D-20).
- [ ] `plugin/conductor/scripts/tests/test-dag.sh` — cas `--scope` (D-13) + cas `reopen` avec `review_regime: full` forcé (D-14).
- [ ] Nouveau fichier `test-check-mission-invariants.sh` (ou extension de suite existante selon le choix d'emplacement du planner, D-15) — cas glob mort détecté / glob vivant silencieux, sur le patron exact de `test-check-doc-drift.sh`.
- [ ] Framework install : aucun — bash pur déjà en place, aucune installation de dépendance requise.

*(Gaps réels — aucune infrastructure de test manquante au sens framework, seulement des cas absents dans des suites déjà robustes)*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `test_sim`/`build_sim`/`clean` sont bien les noms d'outils exacts exposés par un serveur XcodeBuildMCP vivant | SC1 (D-03) | Ce repo n'a pas de `.mcp.json` — aucun serveur MCP réel à interroger ici | Recette humaine sur un lab iOS avec XcodeBuildMCP réellement connecté, hors périmètre d'exécution de cette phase (deferred, comme SC2 de la Phase 19) |
| Release racine + tag annoté + release GitHub (SC7, dernier item) | SC7 | Nécessite validation humaine explicite avant tag (discipline de release du CLAUDE.md racine) — n'appartient pas à l'exécution de cette phase | Après merge, sous checkpoint humain : bump VERSION/plugin.json/marketplace.json, tag annoté, `gh release create`, `check-release-tag.sh --remote` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
