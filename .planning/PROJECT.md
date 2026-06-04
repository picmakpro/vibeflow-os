# VibeFlow Dev Orchestrator (VFDO)

## What This Is

Un nouveau module `dev-orchestrator/` du package vibeflow-os qui transforme VibeFlow en
unique point d'entrée du développement technique : un agent dev-expert orchestre GSD et
Superpowers en coulisse, route chaque intention vers le bon skill, et parle un vocabulaire
100% VibeFlow. L'utilisateur installe uniquement VibeFlow ; tout le reste (install des
dépendances, init projet) en découle.

## Core Value

Depuis une install VibeFlow fraîche, dire « aide-moi à dev cette feature » déclenche le
pipeline GSD complet (brainstorm → plan → execute → test) sans jamais taper une commande
`gsd-*` ni savoir que GSD/Superpowers existent.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Agent routeur `vibeflow-dev` (langage naturel → bon skill GSD/superpowers)
- [ ] Index des skills GSD auto-généré (factuel, jamais d'hallucination de nom)
- [ ] Couche d'abstraction : verbes `/vf-*` + traduction de vocabulaire
- [ ] Bootstrap d'auto-installation non-interactif (GSD + Superpowers) avec fallback manuel
- [ ] Vérification (tests + gates de densité)

### Out of Scope

- Fork/réécriture des skills GSD — on délègue, on n'absorbe pas (maintenir GSD à jour gratuitement)
- Support multi-runtime au-delà de ce que GSD fait déjà — hors périmètre VibeFlow
- Traduction exhaustive de tous les artefacts GSD — seul le vocabulaire exposé à l'utilisateur

## Context

- Repo : vibeflow-os (distribution méthodologique, modules versionnés via `vibeflow-update.sh`).
- Modules existants servant de modèle : `validator/` (agent-only), `skill-creator/` (agent + skills).
- Mécanisme d'install confirmé : `vibeflow-update.sh:124-127` copie `AGENT.md` → `.claude/agents/<mod>.md`
  (format subagent natif Claude Code).
- GSD installé localement : `get-shit-done-cc@1.40.0` (binaire `gsd-sdk`, dossier `~/.claude/get-shit-done/`).
- Superpowers installé : plugin `superpowers@claude-plugins-official` (v5.1.0).
- Faisabilité auto-install étudiée 2026-06-04 : les deux installables en non-interactif (cf. spec §7).
- Spec de référence : `docs/superpowers/specs/2026-06-04-dev-orchestrator-design.md`.

## Constraints

- **Tech stack**: Bash (scripts) + Markdown (agent/skills/references) — cohérent avec les modules existants.
- **Densité (charte VibeFlow)**: agent ≤250L, skills ≤500L — gate `check-file-size.sh`.
- **Dépendances**: GSD (npm) + Superpowers (plugin Claude Code) — auto-install, jamais bloquant.
- **Non-interactif**: aucune commande d'install ne doit attendre une saisie ; `gsd-new-project` (interactif) ne se lance que sur confirmation explicite.
- **Anti-hallucination**: l'index des skills GSD est généré depuis le disque, jamais écrit à la main.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| D1 — Nouveau module `dev-orchestrator/` | Cohérent avec validator/skill-creator, versionné, réplicable | — Pending |
| D2 — Abstraction hybride (agent NL + verbes `/vf-*`) | Max de langage naturel + handles nommés pour l'autonomie | — Pending |
| D3 — Install auto, init projet sur confirmation | `gsd-new-project` est interactif : ne pas le lancer à vide | — Pending |
| D4 — Index 100% auto-généré, pipeline documenté dans l'agent | Index frais sans maintenance ; intelligence dans l'agent | — Pending |
| D5 — Définition via `AGENT.md` | Mécanisme `vibeflow-update.sh` prouvé (validator) | ✓ Good |
| D6 — Verbes au maximum, invocables par l'agent lui-même | Pilotage autonome + raccourcis utilisateur | — Pending |

---
*Last updated: 2026-06-04 after initial scaffolding from design spec*
