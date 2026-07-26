# VibeFlow OS — plugin & marketplace (charte rouverte 2026-07-26)

## What This Is

Le repo de **distribution** du framework VibeFlow : un plugin Claude Code à **17 modules
toggables** sous `plugin/` (marketplace + engine d'install scopé `vibeflow-update.sh`), couvrant
le développement (`dev-orchestrator` + équipe de mission), le design, le planning d'altitude lab,
la mémoire (consolidator 5 piliers), la gouvernance (conductor, hôte du team-kernel), l'audit
(validator + infrastructure-audit + audit-architecture), le test mobile, et 3 bundles métier
(business-pilot, content, growth). La doctrine méthodologique (Core v4.2, 12 patterns, 5 skills)
est livrée dans les labs via le module `reference`.

> Historique : le projet a démarré (2026-06-04) comme un seul module `dev-orchestrator/`. La
> charte initiale décrivait ce périmètre mono-module — le repo distribue aujourd'hui un
> framework multi-métier complet.

## Core Value

Depuis une install VibeFlow fraîche, dire « aide-moi à dev cette feature » déclenche le
pipeline GSD complet (brainstorm → plan → execute → test) sans jamais taper une commande
`gsd-*`. Depuis la **bascule agentique** (v2.33.0), c'est l'agent `vibeflow-dev` qui détecte
l'intention et invoque les briques directement — plus de couche de verbes-synonymes.

## Requirements

### Validated

- [x] Agent routeur `vibeflow-dev` (langage naturel → bonne brique GSD/superpowers) — v1, 14/14
      requirements complétés (ROUT/IDX/ABS/BOOT/VERIF), puis refondu en modèle agentique v2.33.0
- [x] Index des skills GSD auto-généré (factuel, jamais d'hallucination de nom)
- [x] Bootstrap d'auto-installation non-interactif (GSD + Superpowers) avec fallback manuel
- [x] Vérification : 37 suites de tests en CI + gates machine (densité, agents, versions, tags)
- [x] Install UX à toggles (plugin + `/vibeflow-install`, scope user/project/local) — 17/17
- [x] Doctrine dev consolidée (SOLID/DRY/KISS/YAGNI/Clean Archi/Clean Code/TDD) — 12/12
- [x] Mémoire vivante + swarm (ADR-052/053, shippé v2.28.0)
- [~] Couche d'abstraction verbes `/vf-*` — livrée en v2.31.0 puis **délibérément supprimée**
      en v2.33.0 (bascule agentique) : l'abstraction est portée par l'agent, pas par des verbes

### Active

- [ ] Phase 13 — Pont spec → feuille de route, **sans verbe** : découverte outillée (13-01) +
      câblage de l'ingestion dans l'agent (13-02) — clôt le milestone `vf-routing`
- [ ] Milestone `gsd-migration` (en attente) : `get-shit-done-cc` → `@opengsd/gsd-core`,
      go/no-go d'abord (Phase 10)
- [ ] Sortie du statut expérimental de `mobile-test`(-team) : premier run réel vert tracé

### Out of Scope

- Fork/réécriture des skills GSD — on délègue, on n'absorbe pas (maintenir GSD à jour gratuitement)
- Support multi-runtime au-delà de ce que GSD fait déjà — hors périmètre VibeFlow
- Toute couche de synonymes/reframe de vocabulaire — enterrée par la bascule agentique
  (v2.33.0) : ne jamais la recréer

## Context

- Repo : `picmakpro/vibeflow-os`, **public**, installé via `claude plugin marketplace add` +
  `install vibeflow` (zéro-auth). Source des modules = cache du plugin (plus de git clone).
- Discipline de release **non négociable** : tout bump de `VERSION` racine = tag annoté `vX.Y.Z`
  poussé (`scripts/check-release-tag.sh --remote` → ✓) + triade par module + badges/historique
  des 2 README (gate `check-version-sync.sh`).
- Dépendances externes : GSD (`@opengsd/gsd-core`, npm) + Superpowers (plugin) — auto-installées
  par `ensure-deps.sh` (versions locales : voir l'install du lab, pins non gelés dans la charte).
- Registres de vérité : `docs/ADR.md` (ADR-046+ complets, définitions canoniques des héritées),
  `docs/superpowers/specs/` (9 documents), `.planning/` (ce dossier), `reports/` (audits).
- État courant détaillé : `.planning/STATE.md` · jalons : `.planning/MILESTONES.md` ·
  cartographie : `.planning/codebase/` (régénérée 2026-07-26).

## Constraints

- **Tech stack** : Bash portable (ADR-054 : Windows ok, pas de jq/grep -P/sed -i obligatoires)
  + Markdown (agents/skills/references) + JSON (manifestes, hooks).
- **Densité (ADR-029)** : agents ≤ 250 L, skills ≤ 500 L, bootstrap ≤ 2000 tokens.
- **Agents natifs machine-enforced (ADR-044)** : `check-agents.sh` (description + model +
  memory requis, `vf-internal` pour les workers).
- **Jamais de fix sans validation humaine (ADR-031)** — la vigilance runtime est ADR-056.
- **Anti-hallucination** : tout index/compteur exposé est généré depuis le disque ou gaté.
- **Non-interactif** : aucune commande d'install n'attend une saisie ; `gsd-new-project`
  seulement sur confirmation explicite.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| D1 — Nouveau module `dev-orchestrator/` | Cohérent avec validator/skill-creator, versionné, réplicable | ✓ Good — et généralisé : 17 modules sur le même moule |
| D2 — Abstraction hybride (agent NL + verbes `/vf-*`) | Max de langage naturel + handles nommés | ✗ **Renversée** (v2.33.0) : la façade de verbes doublait le catalogue gsd-* — modèle 100 % agentique |
| D3 — Install auto, init projet sur confirmation | `gsd-new-project` est interactif : ne pas le lancer à vide | ✓ Good |
| D4 — Index 100% auto-généré, pipeline documenté dans l'agent | Index frais sans maintenance ; intelligence dans l'agent | ✓ Good |
| D5 — Définition via `AGENT.md` | Mécanisme `vibeflow-update.sh` prouvé (validator) | ✓ Good |
| D6 — Verbes au maximum, invocables par l'agent lui-même | Pilotage autonome + raccourcis utilisateur | ✗ **Renversée** (v2.33.0) avec D2 — subsistent `vf-auto`/`vf-dev` + les 6 commandes de gouvernance |
| D7 — Team-kernel transverse hébergé par `conductor` | Le pattern manager→workers→juges sert tous les métiers | ✓ Good (v2.34.0, ADR-053/057) |

---
*Last updated: 2026-07-26 — charte rouverte : périmètre 17 modules, D2/D6 actées renversées
(bascule agentique), requirements v1 validés, actifs réalignés sur Phase 13 + gsd-migration.
Précédent : 2026-06-04 (scaffolding initial mono-module).*
