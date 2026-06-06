# VERSION

**VibeFlow-Reference** : v2.1
**Date de release** : 2026-05-28
**Type** : Enrichissement additif (Core v4.1 → v4.2 — ajout principe P9 « Modulariser pour la cognition »)

## Contenu

- 3 documents methodologiques fondateurs (CORE v4.1, PHILOSOPHY, EXPLAINED)
- **11 patterns architecturaux universels** (vs 8 en v1.1) avec exemples fictifs : ajout des patterns 09 (meta-procedures), 10 (plan-review adversarial), 11 (halt-conditions)
- 1 lexique VibeFlow enrichi (+16 termes v4.1) + 1 guide dire/ne pas dire (+12 entrees v4.1) + 1 mapping forks
- **33 templates generiques** (8 agents refondus ≤ 250L, 5 docs, 5 memory, 5 triggers, 1 rule) + **4 skills** (vs 1 en v1.1) : debugger, agent-density-auditor, safe-execute, skill-creator
- 1 exemple fictif complet : PetitsCoursFlow (Sophie K., professeure de musique)
- README client + licence d'usage personnel

## Changelog v1.1 → v2.0 (2026-05-19)

Saut majeur : alignement VibeFlow Core v4.0 → **v4.1**. 7 zones d'enrichissement issues des Sessions 044 et 044 amendée du Lab.

### Ajouts methodologie

- **`methodology/VIBEFLOW_CORE.md` enrichi v4.1** (612L → 759L) : 7 zones additives intégrées (charte densité agents, architecture skills natif Claude Code, garde-fou runtime, pattern Adversarial Plan-Review, Iron Law fresh-evidence + critères binaires, méta-procédures structurées, halt conditions + anti-drift). 8 principes universels P1-P8 intacts.
- **`methodology/VIBEFLOW_EXPLAINED.md` enrichi** (270L → 350L) : nouvelle section "Nouveautés v4.1" avec analogies pédagogiques (densité agents = cerveau saturé, architecture skills = réflexes + bibliothèque, méta-procédures = recette stricte, garde-fou méta = notation qui ne s'exécute pas).
- **`methodology/VIBEFLOW_PHILOSOPHY.md`** : note v4.1 en tête (pointeur vers CORE pour le détail).
- **3 nouveaux patterns** (architecturaux universels) :
  - `patterns/09-meta-procedures.md` (132L) — `safe-execute` (5 phases mono-tâche) + `god-execution` (8 phases multi-sprints autonome)
  - `patterns/10-plan-review-adversarial.md` (167L) — 2 agents distincts sessions fraîches + Judge si divergence (anti-echo-chamber)
  - `patterns/11-halt-conditions.md` (157L) — 5 codes HALT universels pour exécution autonome
- **3 patterns enrichis** : `03-agents.md` (charte densité + frontmatter natif), `04-skills.md` (3 niveaux chargement + 1% Rule + 500L), `06-capitalisation.md` (Iron Law fresh-evidence + critères binaires + 7 anti-drift mechanisms)
- **`patterns/README.md`** : passe à 11 patterns avec carte de lecture par usage (découvrir / setup / forker / autonomie / audit)

### Ajouts vocabulaire

- **`vocabulary/lexique.md`** : +16 termes v4.1 (charte densité, bootstrap-skill, on-demand skill, 1% Rule, safe-execute, god-execution, Adversarial Plan-Review, Iron Law fresh-evidence, critère binaire, halt condition, anti-drift, context rot, garde-fou runtime, convention fantôme, agent-density-auditor, skill-creator)
- **`vocabulary/dire-ne-pas-dire.md`** : +12 entrées section "Vocabulaire v4.1 (rigueur exécution)"

### Refonte templates

- **8 templates agents** tous refondus ≤ 250 lignes body (charte densité ADR-029) :
  - `lead-template.md` : 543L → **96L body** (refonte totale + ajout `_reference/lead-knowledge.md` 529L pour le savoir détaillé)
  - `reporter-template.md` : 475L → **155L body**
  - `reviewer-template.md` : 306L → **141L body**
  - `tester-template.md` : 364L → **130L body** (+ skill `tdd` optionnel)
  - `explorer-template.md` : 257L → **146L body**
  - `business-agent-template.md`, `clarity-feature-template.md`, `contracts-template.md` : déjà conformes
- **Frontmatter natif Claude Code** (ADR-030 révisée) : `skills:` flat (préchargement auto). Aucun champ inventé (`bootstrap_skills` / `on_demand_skills` deprecated ADR-031).

### Ajouts skills (3 nouveaux templates)

- `skills/agent-density-auditor/` — Audit + plan migration + gate densité agents (174L SKILL.md + scripts measure/plan/validate + 3 references thresholds/migration_patterns/agent_anatomy)
- `skills/safe-execute/` (339L) — Procédure stricte 5 phases (Clarifier → Planifier → Vérifier plan → Implémenter → Vérifier impl). Fortement anonymisé pour distribution.
- `skills/skill-creator/` (485L) — Pipeline officiel Anthropic pour créer/itérer un skill custom (SKILL.md seul, sans sous-agents/scripts pour ne pas surcharger la distribution)
- `skills/debugger/` : frontmatter réparé conforme ADR-029

### Refonte mineure

- `docs/CLAUDE-template.md` : enrichi v4.1 (sections "Conformité méthodologique v4.1", "Méta-skills universels", "Workflow v4.1 10 étapes", registre EVALS au tableau MEMOIRE PROJET)
- `memory/*-template.md` : mention `Source : VibeFlow Core v4.1`
- `rules/rule-template.md` : mention `Source : VibeFlow Core v4.1`
- `triggers/plan-sprint-template.md` : "Sizing (V3 Lean)" → "Sizing (Auto-Split v4.1)"

## Compatibilite

- Aucune dependance technique
- Lisible avec n'importe quel editeur de texte ou Markdown viewer
- Encoding UTF-8

## Breaking changes (vs v1.1)

- **Convention frontmatter agents** : si tu utilisais un champ inventé `bootstrap_skills.contextual` ou `on_demand_skills` (par mimétisme du Lab Session 044 v1 — depuis corrigé via ADR-031), migrer vers `skills:` natif flat. Voir skill `agent-density-auditor` mode plan/apply pour migration assistée.
- **Densité agents** : les anciens templates V3.1 pouvaient avoir 500+ lignes inline. La v2.0 impose ≤ 250L body via extraction `_reference/<agent>-knowledge.md`.

## Prochaines versions

Voir le changelog interne (`README-INTERNAL.md`, non distribue).

---

> Cette archive est figee. Si une mise a jour majeure intervient, une v2.1 (mineure) ou v3.0 (majeure) te sera livree separement.
