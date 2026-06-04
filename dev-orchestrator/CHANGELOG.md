# CHANGELOG — dev-orchestrator

## [v1.0.0] — 2026-06-04

### Module initial

**Squelette du module**
- Structure conforme aux modules vibeflow-os (`VERSION`, `CHANGELOG.md`, `README.md`, `references/`, `scripts/`)
- Type : agent + multi-skills + scripts (orchestrateur de développement)

**Index auto-généré (D4 — anti-hallucination)**
- Script `build-gsd-index.sh` qui génère `references/gsd-skills-index.md` à partir des skills GSD réellement installés (`~/.claude/skills/gsd-*`)
- Aucun nom de skill écrit en dur : extraction factuelle du frontmatter (`name` + `description`)
- Contrat de sortie `VF_INDEX_OUT` surchargeable (consommé par le hook post-install, D7)
- Idempotent : ré-exécution = régénération complète (IDX-02)
- Couvre IDX-01 (index factuel) et IDX-02 (script ré-exécutable + paramétrable)

### À venir (autres plans de la phase)
- Agent routeur dev-orchestrator (Plan 03)
- Verbes `/vf-*` (Plan 04)
- Bootstrap auto-install + hook post-install (Plan 05)
- README complet (Plan 05)
