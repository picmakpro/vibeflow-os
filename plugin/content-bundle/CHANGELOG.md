# CHANGELOG — content-bundle

## [v1.1.0] — 2026-07-16 (ADR-048 — orchestrateur métier)

### Modifié
- Doctrine d'orchestration réconciliée : un **orchestrateur métier** (`chef-editorial`, skill
  `metier-orchestration`) est posé d'office (≥2 spécialistes) ; le `conductor` redevient strictement méta.

## [v1.0.1] — 2026-07-05 (ADR-044)

### Corrigé
- BUNDLE.md : l'énumération d'instanciation inclut `description` (le frontmatter cible des
  blueprints l'avait, mais la consigne de recopie l'omettait — les agents sortaient muets).

## [v1.0.0] — 2026-06-11

### Création du bundle métier content (ContentFlow)

Premier bundle métier **doc-only** du plugin vibeflow-os. Il ne s'installe pas comme un agent
exécutable : il porte des **blueprints** que `vf-new-lab` (module `conductor`) lit et instancie en
agents natifs ≤250L dans le lab cible.

- **Manifeste** `content/BUNDLE.md` : métier (content / chaîne brief→livrable→distribution), profil
  de rigueur planning (**standard**), extension de domaine (**editorial/**), vocabulaire métier
  (campagne / pièce / angle / pilier / cadence), les 3 agents, modules recommandés et le flux
  d'instanciation lu par `vf-new-lab`.
- **3 blueprints d'agents** (`content/agents/`) prêts à instancier façon `business-agent`, chacun
  conçu pour s'instancier **≤250L** (savoir déporté en skills injectés via frontmatter `skills:`,
  jamais inliné — charte densité ADR-029) :
  - `strategist.blueprint.md` (sonnet) — stratège éditorial, cadre chaque pièce avant production.
  - `scriptwriter.blueprint.md` (sonnet) — rédacteur/idéateur, produit hooks + livrable.
  - `repurposer.blueprint.md` (sonnet) — repurposing/distribution multi-plateformes.
- **Spec d'extension** `content/domain/extension-spec.md` : structure exacte de `editorial/`
  (LIGNE-EDITORIALE / CALENDRIER / AUDIENCE / FORMATS / PILIERS) à scaffolder.
- **Registres** `content/registres.md` : les 5 registres canon (DECISIONS / LEARNINGS / BLOCKERS /
  JOURNAL / EVALS), convention d'IDs, ce que chaque agent capitalise, et le pont planning↔mémoire.

### Châssis doctrinal embarqué

- Principes Core **P1/P3/P4/P5/P7/P8/P9** référencés (jamais redupliqués — source : module
  `reference`, `VIBEFLOW_CORE.md`).
- Filet d'audit obligatoire câblé : agent `vibeflow-validator` (module `validator`) + skill
  `audit-architecture` (P8, verdict bloquant sur le générateur brief→output).
- Orchestration **déléguée** au module `conductor` (`vibeflow-conductor`) : le bundle ne re-code
  aucun orchestrateur ; les agents métier n'orchestrent pas.
- Décision de design tracée : **condensation 6 rôles → 3 agents** + le **gate de clarté** matérialisé
  comme couche `audit-architecture` (pas un agent) — à inscrire en DECISIONS du lab (cf. BUNDLE.md).

### Dépendances

`planning-core`, `consolidator`, `audit-architecture`, `validator`. Orchestration via `conductor`
(transitive — `vf-new-lab` est le point d'entrée).
