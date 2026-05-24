# CHANGELOG — validator

## [v1.0.0] — 2026-05-24

### Initial release

**Agent natif Claude Code**
- `AGENT.md` — frontmatter `name`, `description`, `model: opus`, `memory: project`, `skills:` (5 skills natifs)
- 183 lignes (charte ADR-029 ≤250L respectée)
- Modèle Opus pour orchestration complexe multi-skills

**Skills délégués (frontmatter native ADR-030)**
- `consolidator` — mémoire 4 piliers
- `infrastructure-audit` — drift Anthropic
- `agent-density-auditor` — charte ADR-029
- `dette-detector` — 7 signaux dette
- `checkpoint` — cohérence Lab

**4 phases d'audit**
1. Infrastructure technique (bloquant si ERROR)
2. Densité agents
3. Dette documentaire + mémoire
4. Synthèse + recommandations actionables

**Output**
- Rapport `reports/validator/YYYY-MM-DD-validator.md`
- Score 0-100 + status PASS/WARN/FAIL
- Actions prioritaires par sévérité

**Iron Laws**
- Détecter, jamais corriger sans validation humaine (ADR-031)
- Déléguer aux skills, ne pas réimplémenter (LRN-105)
- Snapshot avant audit, snapshot après

**Pré-requis installation**
- Modules `consolidator` v1.0.0+ et `infrastructure-audit` v1.0.0+ installés
- Skills natifs Lab : `agent-density-auditor`, `dette-detector`, `checkpoint`

### Validé en production
- Lab VibeFlow (cobaye) — Session 047
- Agent déployé `.claude/agents/vibeflow-validator.md`
- Frontmatter `skills:` native (ADR-030) reconnu par Claude Code 2.1.150

### Limites connues v1.0.0
- Pas d'auto-fix (par design)
- Rapport markdown statique (pas de dashboard)
- Skills doivent être installés au préalable
- Score 0-100 indicatif, pas de gate auto-bloquant

### Références
- ADR-029, ADR-030 (révisée), ADR-031, ADR-032
- LRN-105, LRN-106
