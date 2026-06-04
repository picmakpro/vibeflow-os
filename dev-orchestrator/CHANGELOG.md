# CHANGELOG — dev-orchestrator

## [v1.1.0] — 2026-06-04

### Ajouté
- **Verbe `/vf-map`** — cartographie d'un code existant (délègue à `gsd-map-codebase`),
  construit selon la discipline `writing-skills`. Complète `vf-init` (bootstrap + démarrage
  projet) pour couvrir explicitement le parcours « projet existant ». Porte le total à
  **13 verbes `/vf-*`**.
- README : section Usage enrichie — routage NL init/map, parcours types (premier contact,
  projet existant, tâche rapide, autonomie), verbe `vf-map`.

## [v1.0.0] — 2026-06-04

### Module initial complet (5 plans, phase 01-dev-orchestrator)

**Squelette du module**
- Structure conforme aux modules vibeflow-os (`VERSION`, `CHANGELOG.md`, `README.md`, `references/`, `scripts/`)
- Type : agent + multi-skills + scripts (orchestrateur de développement)

**Index auto-généré (D4 — anti-hallucination)**
- Script `build-gsd-index.sh` qui génère `references/gsd-skills-index.md` à partir des skills GSD réellement installés (`~/.claude/skills/gsd-*`)
- Aucun nom de skill écrit en dur : extraction factuelle du frontmatter (`name` + `description`)
- Contrat de sortie `VF_INDEX_OUT` surchargeable (consommé par le hook post-install, D7)
- Idempotent : ré-exécution = régénération complète (IDX-02)

**Agent routeur (Plan 03)**
- `AGENT.md` (`vibeflow-dev`, ≤250L) : routage langage naturel → action, 14 cibles distinctes
- Doctrine pipeline déportée `references/GSD-PIPELINE.md` (chargée on-demand)
- Ne nomme jamais GSD/Superpowers ; reframe en vocabulaire VibeFlow

**Couche d'abstraction (Plan 04)**
- 12 verbes `/vf-*` thin delegators (construits via `writing-skills`)
- `references/vocabulary-map.md` (traduction GSD → VibeFlow)

**Bootstrap + intégration (Plan 02 & 05)**
- `ensure-deps.sh` : auto-install non-interactif idempotent de GSD + Superpowers, fallback manuel
- `vibeflow-update.sh` étendu : copie des references d'un module agent sous `.claude/agents/<mod>-references/` (D7) + hook post-install régénérant l'index (IDX-02)
- Suite `test-dev-orchestrator.sh` (4 axes VERIF-01 + densité `wc -l` VERIF-02)
