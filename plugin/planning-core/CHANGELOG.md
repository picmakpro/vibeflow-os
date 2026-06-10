# Changelog — planning-core

## v1.0.0 — 2026-06-10

Release initiale. Socle de planning & gestion documentaire **universel** extrait de la logique
GSD `.planning/`, débarrassé du couplage dev et rendu adaptatif par métier.

### Ajouté
- Skill `vf-planning` — scaffoldeur/maintaineur thin, prose agent-driven : lit le métier du lab,
  choisit un profil de rigueur, instancie le tronc commun en l'adaptant, établit le pont mémoire.
- Tronc commun = 7 artefacts (`PROJECT`, `STATE` ★, `ROADMAP`, `REQUIREMENTS`, `MILESTONES` +
  `milestones/`, `phases/NN/PLAN`+`SUMMARY`, `config.json`).
- 3 profils de rigueur (léger / standard / complet) + mapping métier → profil (`references/PROFILES.md`).
- Doctrine anti-biais (`references/GUIDE.md`) : tronc invariant, extension de domaine adaptée au
  métier (jamais imposée), STATE comme clé de voûte.
- Pont `.planning/` ↔ `.claude/memory/` sans duplication (`references/bridge-memory.md`).
- 8 gabarits universels neutres-métier (`references/templates/`).

### Notes
- `type: skill + references`. Aucune dépendance (`requires: []`) — fonctionne seul.
- v1 = **structure + discipline manuelle**. L'automatisation de la maintenance de STATE (hook
  SessionEnd, mise à jour auto) est un incrément ultérieur (« moteur »).
- Origine : ADR-038 (candidate). Complémentaire du module dev `dev-orchestrator` (qui produit un
  `.planning/` dev via GSD) — `planning-core` est l'étage universel en dessous.
