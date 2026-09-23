---
phase: VFDO-38-portabilit-multi-runtime-livraison-canal-d-install-migration
plan: "07"
subsystem: infra
tags: [bash, codex-adapter, uninstall, coexistence]

requires:
  - phase: "38-05"
    provides: "register-codex-agent.sh (pose d'un rôle .toml depuis un agent VibeFlow)"
  - phase: "38-06"
    provides: "check-artifact-fidelity.sh --coexistence-report + runtime-registry.sh set-active"
provides:
  - "resolve_posed_agent_artifact() : contrat multi-lignes, cumule root AGENT.md ET agents/*.md"
  - "register-codex-agent.sh --remove : retrait idempotent d'un rôle .toml, sans dépendance à node"
  - "unregister_codex_agent_if_applicable() : câblée dans uninstall_module(), avant suppression des artefacts source"
  - "record_codex_runtime_if_applicable() : écrit le registre de runtime depuis le chemin d'install réel"
affects: [vibeflow-update.sh, register-codex-agent.sh]

actuals:
  tokens: 92000
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Contrat multi-lignes (un chemin par ligne sur stdout) au lieu d'un chemin unique — les deux sources (root/dir) deviennent CUMULATIVES, jamais mutuellement exclusives"
    - "Comparaison d'ensembles de noms via comm -3 sur listes triées, jamais un comptage (D-38 prohibition)"
    - "Retrait par rôle (register-codex-agent.sh --remove) plutôt qu'un rm -rf global du répertoire — un uninstall_module() d'un seul module ne doit jamais supprimer les rôles d'un autre module encore installé en coexistence"
    - "unregister_codex_agent_if_applicable() ne filtre PAS sur le runtime détecté au moment de l'appel (contrairement à register_) — un rôle orphelin doit être nettoyé même si le runtime résolu maintenant a changé"

key-files:
  created: []
  modified:
    - plugin/_internal/vibeflow-update.sh
    - plugin/_internal/runtime-adapter/register-codex-agent.sh
    - plugin/_internal/tests/test-vibeflow-update.sh
    - .planning/ROADMAP.md

key-decisions:
  - "uninstall_module() dévie délibérément de la doctrine 'rm -rf $CODEX_HOME/agents/vibeflow/' documentée en 38-CONTEXT.md:363 (pensée pour un retrait GLOBAL) — retrait rôle par rôle à la place, uninstall --all atteint le même état final en bouclant uninstall_module par module, sans risque de sur-suppression d'un module tiers en coexistence."
  - "record_codex_runtime_if_applicable() modifie délibérément vf_runtimes.active (pas seulement installed[]) via runtime-registry.sh set-active --confirmed — ce script n'expose aucun verbe plus étroit et vit hors périmètre de ce plan (plugin/conductor/**)."
  - "Le second volet de CODEX-B6 (texte faux de check-artifact-fidelity.sh:175) n'est PAS corrigé ici — fichier hors périmètre strict, consigné en dette D-38-R avec fait mesuré et déclencheur de reprise plutôt que silencieusement oublié ou corrigé hors mandat."

patterns-established:
  - "Preuve rouge->vert par snapshot du code pré-fix (git show HEAD:<fichier>) rejoué dans un lab isolé, plutôt qu'un stash/checkout sur un worktree partagé par 3 workers en parallèle — permet une trace RED complète sans jamais toucher à l'état de travail des autres workers."

requirements-completed: [CODEX-B4, CODEX-B5, CODEX-B6]

coverage:
  - id: D1
    description: "resolve_posed_agent_artifact() rend TOUS les agents d'un module (root + agents/*.md cumulés), team-kernel complet enregistré côté Codex, module mono-agent non régressé"
    requirement: "CODEX-B4"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh T49 (67/67) — comm -3 vide (source 10 vs posé 10), témoin vibeflow-validator présent"
        status: pass
    human_judgment: false
  - id: D2
    description: "uninstall_module()/uninstall --all retirent réellement chaque rôle .toml posé, résidus runtime Codex légitimes intacts"
    requirement: "CODEX-B5"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh T50 (67/67) — comm vide avant/après, 6 résidus légitimes (sessions/, cache/, log/, tmp/arg0/, models_cache.json, sqlite) contenu inchangé"
        status: pass
    human_judgment: false
  - id: D3
    description: "Coexistence sans hooks déclarée depuis le chemin réel d'install/status sans pré-semage manuel ; jamais pour un runtime claude seul"
    requirement: "CODEX-B6 (1er volet)"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh T51 (67/67) — ligne [fidelity-coexistence] présente à l'install ET au status sans pré-semage ; témoin anti-parasite runtime claude : 0 ligne coexistence"
        status: pass
    human_judgment: false
  - id: D4
    description: "Texte faux du gate hors périmètre consigné en dette explicite avec fait mesuré et déclencheur de reprise"
    requirement: "CODEX-B6 (2e volet, hors périmètre fichier de ce plan)"
    verification:
      - kind: other
        ref: ".planning/ROADMAP.md — entrée D-38-R, citant check-artifact-fidelity.sh:175 verbatim"
        status: pass
    human_judgment: false

duration: ~2h
completed: 2026-08-29
status: complete
---

# Phase 38 Plan 07: Codex — agents multi-fichiers, retrait à l'uninstall, coexistence déclarée — Summary

**Le canal d'install Codex enregistre désormais tout ce qu'il pose (team-kernel complet), défait tout ce qu'il a posé (uninstall symétrique), et annonce sa coexistence sans hooks depuis le chemin réel d'install — les trois écarts mesurés en conditions réelles le 2026-08-29 entre ce que les lots 30→06 rendaient ATTEIGNABLE et ce que l'install faisait vraiment.**

## Performance

- **Tasks:** 3 (CODEX-B4 tracer TDD, CODEX-B5 TDD, CODEX-B6 TDD)
- **Files modified:** 4 (0 créés, 4 modifiés)
- **Commits:** 2 (fix groupé des trois bloquants + dette ROADMAP séparée)

## Accomplishments

- `resolve_posed_agent_artifact()` cumule désormais AGENT.md racine ET tous les `agents/*.md`
  d'un module (au lieu de les traiter comme mutuellement exclusifs) — `report_artifact_fidelity()`
  et `register_codex_agent_if_applicable()` bouclent sur le nouveau contrat multi-lignes. Un
  module comme `dev-orchestrator` (root + 4 `agents/*.md`) enregistre désormais ses 5 rôles côté
  Codex au lieu d'un seul.
- `register-codex-agent.sh --remove` (nouveau mode, sans dépendance à `node`) + nouvelle
  `unregister_codex_agent_if_applicable()`, câblée dans `uninstall_module()` entre `backup_module`
  et la suppression des artefacts source — `uninstall`/`uninstall --all` retirent réellement
  chaque rôle `.toml` posé, sans toucher au bruit runtime légitime de Codex (`sessions/`, `cache/`,
  `log/`, `tmp/arg0/`, `models_cache.json`, `*.sqlite`).
- Nouvelle `record_codex_runtime_if_applicable()`, câblée dans `install_module()`/`update_module()`
  juste avant le bloc `--coexistence-report` déjà posé en 38-06 — la déclaration de coexistence se
  déclenche désormais depuis le chemin d'install réel, sans pré-semage manuel de
  `.planning/config.json`.
- Dette D-38-R consignée dans `.planning/ROADMAP.md` pour le second volet de CODEX-B6 (texte faux
  de `check-artifact-fidelity.sh:175`, hors périmètre fichier de ce plan).

## Task Commits

1. `8ba6d51` — CODEX-B4/B5/B6 (fix groupé, les trois bloquants partagent le même fichier
   `vibeflow-update.sh` et le nouveau contrat `resolve_posed_agent_artifact()` dont B5/B6
   dépendent directement).
2. `5eed8e5` — dette D-38-R (`.planning/ROADMAP.md`).

## Issues Encountered

- **Ligne de plan vs code réel** : les numéros de ligne du plan (2214, 2895, 2589-2630) ne
  correspondaient plus exactement au fichier au moment de l'exécution (d'autres workers du même
  worktree partagé avaient déjà ajouté du contenu). Résolu par `grep -n` sur les noms de fonctions
  plutôt que sur les numéros de ligne littéraux — jamais de correction à l'aveugle sur un numéro
  périmé.
- **Preuve RED sans toucher au worktree partagé** : impossible de `git stash`/`checkout` pour
  rejouer le code pré-fix (3 workers actifs sur ce même worktree). Contourné par
  `git show HEAD:<fichier>` vers un scratch isolé, avec reconstruction complète de l'arborescence
  `_internal/` (lib/, merge-hooks.sh, runtime-cli-dispatch.sh, runtime-adapter/) nécessaire aux
  cascades de résolution — sinon des erreurs de dépendances manquantes masquaient le vrai défaut
  mesuré derrière un échec non lié.

## Verification

Suites rejouées dans l'ordre prescrit par le plan (non-régression, jamais un périmètre de
re-planification) :

1. `test-vibeflow-update.sh` : 67 OK / 0 KO (baseline 63, +4 assertions `ok` des tâches 1-3).
2. `test-manifest.sh` : 62 OK / 0 KO, inchangé (ce plan ne touche aucune logique de manifeste).
3. `test-agent-to-codex.sh` : 13 OK / 0 KO (baseline mesurée au cadrage 7, progression normale —
   fichier d'un autre worker du même worktree, rejoué en lecture seule, aucun KO à rapporter).

Garde-fou final : `~/.claude` (384 fichiers) et `~/.codex/agents/vibeflow` (0 fichier) intacts
avant/après toute la suite.

## Next Steps

- Bloquants 1/2/3 et les 3 défauts de second rang de la même mesure Codex de bout en bout restent
  traités par d'autres workers sur ce même worktree partagé (hors périmètre de ce plan).
- Dette D-38-R (texte faux `check-artifact-fidelity.sh:175`) : à reprendre dès que le worker
  parallèle sur `plugin/conductor/**` livre sa propre correction du même fichier.
- La conversion réelle `settings.json -> hooks.json` pour Codex (surface de hooks prouvée
  exécutante, non ciblée par cette phase) reste un geste dédié à planifier, jamais promis avant
  d'être livré.
