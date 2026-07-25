# CHANGELOG — validator

## [v1.2.1] — 2026-07-25

### Corrigé
- Suppression des 3 skills fantômes du frontmatter (agent-density-auditor / dette-detector / checkpoint, F3) : phases 2-3 s'appuient sur les briques réellement livrées (`check-agents.sh --strict`, grille des 7 signaux, consolidator --audit) ; `/checkpoint` → `/vf-audit` ; référence ADR-056.

## [v1.2.0] — 2026-07-08 (ADR-045)

### Ajouté
- **Contrôle « recherche documentaire avant debug » (ADR-045) en Phase 2.** Le validator exécute
  désormais `bash .claude/scripts/check-debug-research.sh` : il repère les briques de dépannage du
  lab (skills/agents dont name/description matche `debug|diagnos|dépannage|crash|stack trace`) et
  vérifie que chacune porte une phase de recherche documentaire avant le fix (renvoi à
  `doc-research-before-debug`, heading « Recherche documentaire », ou mention `context7`). `✗` =
  finding bloquant agrégé au score ; `⚠` = wrapper qui délègue sans marqueur.
- Phase 2 renommée « Densité + conformité agents ». Output template + Références (ADR-045) mis à jour.
- Le script est fourni par `conductor` (`check-debug-research.sh`) — le validator délègue, ne
  réimplémente pas (Iron Law 2).

## [v1.1.0] — 2026-06-03

### Ajout — Phase 4 : Audit architecture des process (ADR-036)

- Skill `audit-architecture` ajouté au frontmatter `skills:` (6 skills désormais).
- Nouvelle **Phase 4 — Audit architecture des process** (mode scan de lab) : énumère les process générateurs (brief→output), reconstitue leur structure d'audit actuelle, diffère avec la cible (méthode 4 temps), reporte les process sous-audités.
- L'ancienne Phase 4 (Synthèse) devient **Phase 5**. Procédure désormais en 5 phases.
- Description + output template + table de délégation + pré-requis mis à jour.
- Conforme ADR-031 : conçoit et propose, ne matérialise pas (détecter ≠ corriger).
- 203 lignes (charte ADR-029 ≤250L respectée).

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
