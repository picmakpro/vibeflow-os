# CHANGELOG — skill-creator

## [v1.0.4] — 2026-08-30 (Phase 38 — description de frontmatter YAML strict, plan 38-08)

**Patch** :

- **Description de frontmatter passée en scalaire mono-ligne quoté** — la description est désormais un scalaire guillemets doubles mono-ligne (texte strictement inchangé), pour traverser sans perte un parseur YAML strict ET la logique d'extraction de gsd-core (`extractFrontmatterField`). 3 fichiers du module concernés. Gate : `plugin/conductor/scripts/check-description-fidelity.sh` (Phase 38, plan 38-08, FIDE-01/FIDE-02).

## [v1.0.3] — 2026-07-26

### Modifié
- README monté au standard de doc du repo (tagline, Quoi, Installation avec prérequis réels,
  Démarrer en 5 min, Usage, Référence exhaustive vérifiée sur disque, Limites). Contenu vérifié :
  cibles d'install réelles (agent + commande d'incarnation ADR-042 + 2 skills), frontière ADR-057
  descriptive (aucune revendication d'exclusivité).

## [v1.0.2] — 2026-07-25

### Modifié
- ADR-057 : abandon de la revendication « sole authorized channel » au profit d'une frontière descriptive (fabrication de capacités de lab avec eval-loop vs superpowers:writing-skills = doctrine d'écriture).

## [v1.0.1] — 2026-07-04 (ADR-043)

### Modifié
- Canon DECISIONS.md/JOURNAL.md fixé (ADR.md/ITERATION_LOG.md legacy acceptés en lecture) ;
  placeholder `[REFERENCER_ADR]` → `[REFERENCER_DECISION]`.

## [v1.0.0] — 2026-05-24

### Initial release dans vibeflow-os

**Source** : Package `output/skill-creator-universal/` du VibeFlow Lab (créé Session 045, ADR-024 + LRN-101).

**Composants packagés**
- `AGENT.md` : agent minimal `skill-creator` (85 lignes, charte ADR-029)
  - Frontmatter `skills: [skill-creator, skill-creator-workflow]`
  - Règle ABSOLUE : 1 skill par invocation
  - Escalation orchestrating agent pour attribution
- `skills/skill-creator/` : skill officiel Anthropic (248 KB)
  - SKILL.md (33 KB) — moteur de drafting
  - 3 sous-agents : grader, comparator, analyzer
  - 9 scripts Python pour eval/benchmark/loop
  - LICENSE MIT (Anthropic)
  - eval-viewer, assets, references
- `skills/skill-creator-workflow/` : procédure 5 phases (16 KB)
- `INSTALL.md` : guide install manuel original conservé

**Pattern 3 couches stables/mobiles** (LRN-101)
- Couche 1 : Agent (mobile entre Labs : nom + orchestrator)
- Couche 2 : skill-creator Anthropic (stable, figé)
- Couche 3 : skill-creator-workflow (mobile : procédure adaptable)

### Pré-requis runtime

- `vibeflow-update.sh` v1.3.0+ pour support multi-skills par module
- Au moins 1 orchestrating agent existe dans le Lab cible

### Validé en production

Session 045 — Déploiement sur permis-clair-growth (agent 93L + workflow growth 265L).
Session 047 — Packagé dans repo vibeflow-os pour distribution scalable cross-labs.

### Limites connues v1.0.0

- Personnalisation manuelle requise après install ([NOM_LAB] + [ORCHESTRATING_AGENT])
- skill-creator-workflow contient références VibeFlow spécifiques (à adapter pour Labs externes)
- skill-creator (Anthropic) figé — toute évolution Anthropic = repackaging manuel

### Références

- ADR-024 — Skill-creator inclus dans template DevFlow V4
- LRN-101 — Pattern 3 couches stables/mobiles portable entre labs
- VideoFlow-Lab — Lab source du pattern initial
