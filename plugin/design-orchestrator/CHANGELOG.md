# CHANGELOG — design-orchestrator

## [v1.0.0] — 2026-07-08

### Module initial

**Squelette du module** (conforme aux modules vibeflow-os : `VERSION`, `CHANGELOG.md`,
`README.md`, `module.json`, `AGENT.md`, `skills/`, `references/`)
- Type : **agent + skills**. Installé d'office avec `dev-orchestrator` (via ses `requires`).

**Agent routeur `vibeflow-design`** (`AGENT.md`, ≤250L, ADR-044 : description + model + memory)
- Table de routage langage naturel → geste design coulisse (DA-INIT / DESIGN-WORKFLOW par intent
  ACTION / INSPIRATION / CRITIQUE / craft ciblé).
- **Généricité multi-stack** : détection de stack, incarnation du système de design adaptée
  (web CSS/Tailwind · SwiftUI · React Native / Flutter · desktop). Produit des specs + tokens,
  jamais du code framework-locké.
- Doctrine : DA avant refonte, diagnostic avant geste, vérification après craft.
- Reframe systématique ; ne nomme jamais les outils design bruts.

**Verbe `/vf-design`** (`skills/vf-design/`)
- Thin delegator à description riche en wording (auto-invocation langage naturel), délègue à
  `vibeflow-design`. Point d'entrée design unique.

**Références on-demand** (`references/`)
- `DESIGN-WORKFLOW.md` — workflow quotidien (routing intent + complexité QUICK FIX / PLAN MODE /
  FULL DESIGN, checklists par mode, gate de sortie), générique multi-stack.
- `DA-INIT.md` — initialisation de la direction artistique (bible visuelle + section CLAUDE.md +
  système de design incarné selon la stack).
- `design-toolchain.md` — mapping reframe → plugins réels (`ui-ux-pro-max`, `frontend-design`,
  `impeccable`, `superpowers`), vérification de présence et **dégradation gracieuse**.
- `design-vocabulary-map.md` — table de reframe (outils design → vocabulaire VibeFlow).
- `templates/DESIGN.md` + `templates/CLAUDE-design-section.md` — templates génériques (rôles
  stables, incarnation selon stack).

### Origine
- Dérivé et généralisé depuis le kit `design-system-kit` (skills `design` + `design-init-da`,
  initialement Next.js/Tailwind/shadcn) — rendu **stack-agnostique** et aligné sur la doctrine
  VibeFlow (agent routeur + verbe thin + références on-demand + reframe).
