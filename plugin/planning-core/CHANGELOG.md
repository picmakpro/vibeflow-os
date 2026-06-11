# Changelog — planning-core

## v1.1.0 — 2026-06-11

Phases 3-5 (moteur léger universel + auto-infusion + preuve d'universalité). **Sans toucher
`dev-orchestrator`.**

### Ajouté
- **Moteur léger (Phase 3)** : `scripts/check-planning-state.sh` — garde-fou de fraîcheur de la
  clé de voûte `STATE.md` (advisory, portable macOS/Linux, exit codes pour hook). Détecte
  `.planning/` absent (lab non amorcé), STATE absent, STATE périmé. + `scripts/tests/` (6/6 PASS).
- **Auto-infusion + détection métier (Phase 4)** : `references/domain-detection.md` — heuristiques
  de *jugement* (jamais déterministes) pour inférer le métier → profil + extension, et amorcer un
  lab fraîchement installé **sans rien imposer** (le garde-fou surface l'absence de socle, le skill
  pose un socle adapté). Wiring d'un hook SessionStart opt-in documenté (jamais auto-injecté).
- **Preuve d'universalité (Phase 5)** : `references/example-lab-contenu.md` — exemple complet d'un
  socle `.planning/` adapté à un lab NON-dev (éditorial, profil standard, extension `editorial/`).
- Skill `vf-planning` câblé sur ces 3 références + le script.

### Notes
- Type module : `skill + references` → `skill + references + scripts`.
- La maintenance reste **assistée** (advisory), pas automatique forcée — cohérent « structure d'abord ».

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
