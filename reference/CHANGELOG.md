# CHANGELOG — reference

## [v2.1.1] — 2026-06-03

### Pointeur P8 — outillage par-process (ADR-036 Lab)

- `VIBEFLOW_CORE.md` section P8 : ajout d'un pointeur additif vers le module `audit-architecture` (opérationnalise P8 au niveau de chaque process générateur via structures d'audit multi-couches). Décision : pas de nouveau principe Core — `audit-architecture` est à P8 ce que `software-architecture` est à P9.
- P1-P9 intacts. Ajout strictement additif.

## [v2.1.0] — 2026-05-28

### Ajout du principe P9 dans VIBEFLOW_CORE (v4.1 → v4.2)

- `VIBEFLOW_CORE.md` : **9 principes** désormais (P1-P8 intacts + **P9 — Modulariser pour la cognition**).
- P9 : aucune unité (fichier, document, tâche) ne dépasse sa capacité cognitive ; une responsabilité par unité ; frontières enforced par la machine, pas par la prose.
- Origine : doctrine Architecture Logicielle AI-Safe (ADR-035 Lab). Spécialisation dev via le module `software-architecture` ; transposition non-dev via mapping sémantique (P7).
- `content/VERSION.md` aligné (Core v4.2, 9 principes).

## [v2.0.0] — 2026-05-24

### Initial release dans vibeflow-os (version 2.0 héritée du Lab Session 044+)

**Source** : `distributions/VibeFlow-Reference-v2/VibeFlow-Reference-v2.0.zip` (Session 044 amendée, mai 2026)

**Contenu** : 70 fichiers (608 KB)

**Documentation méthodologique** (méthodologie + philosophie + vulgarisation)
- `VIBEFLOW_CORE.md` v4.1 — 8 principes P1-P8 (759 lignes)
- `VIBEFLOW_PHILOSOPHY.md` — Philosophie sous-jacente
- `VIBEFLOW_EXPLAINED.md` — Vulgarisation avec analogies pédagogiques

**11 patterns architecturaux universels** (vs 8 en v1.1)
- 01-constitution
- 02-registres
- 03-agents
- 04-skills
- 05-regles
- 06-capitalisation
- 07-transposition
- 08-evaluer
- 09-meta-procedures (★ nouveau v4.1)
- 10-plan-review-adversarial (★ nouveau v4.1)
- 11-halt-conditions (★ nouveau v4.1)

**Vocabulary**
- Lexique enrichi (+16 termes v4.1)
- Guide dire/ne pas dire (+12 entrées)
- Mapping forks (DevFlow / Mobile / ContentFlow / GrowthFlow / VideoFlow)

**33 templates génériques**
- 5 memory : adr, learnings, blockers, evals, vendors
- 8 agents + contracts : lead, explorer, tester, reporter, reviewer, frontend, backend, validator
- 5 triggers : plan-sprint, fix-bug, checkpoint, arbitrage, implement-feature
- 1 rule template
- 5 docs templates
- 4 skills : debugger, agent-density-auditor, safe-execute, skill-creator

**Exemple complet** : PetitsCoursFlow (Sophie K., professeure de musique) — Lab fictif démontrant tous les patterns.

### Pré-requis runtime

- `vibeflow-update.sh` v1.3.0+ pour support modules doc-only
- Installation : copie `content/` → `docs/reference/` du lab cible

### Validé en production

- Session 045+ du Lab — Référence active dans toutes les sessions méthodologiques
- Session 047 — Packagé dans vibeflow-os pour distribution scalable

### Limites connues v2.0.0

- VIBEFLOW_PHILOSOPHY.md et VIBEFLOW_EXPLAINED.md pas totalement re-rédigés pour v4.1 (note v4.1 en tête seulement)
- Pattern 11-halt-conditions à intégrer opérationnellement avec `infrastructure-audit`
- Skills templates (debugger, agent-density-auditor, safe-execute, skill-creator) sont des copies — toute évolution dans les modules vibeflow-os respectifs doit être resync'ée ici

### Changelog historique (Lab)

- v1.0 (avril 2026) — Première extraction documentation Core v4.0
- v1.1 (mai 2026) — 8 patterns + skill debugger
- **v2.0 (2026-05-19)** — Alignement Core v4.1, 11 patterns, 4 skills, exemple complet

### Références Lab

- Sessions 044 et 044 amendée — Source des enrichissements v4.1
- ADR-024 — skill-creator inclus dans template
- ADR-029 — Charte densité agents
- ADR-031 — Garde-fou support runtime
