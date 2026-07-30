---
phase: 05-packaging-plugin
plan: 01
subsystem: packaging
tags: [plugin, marketplace, hooks, install-ux, claude-code]
requires:
  - "installer/SKILL.md (skill vibeflow-install)"
  - "installer/hooks/session-start (hook 1er lancement, livré Phase 4)"
  - "_internal/vibeflow-update.sh + resolve-deps.sh + build-module-catalog.sh (engine)"
provides:
  - ".claude-plugin/plugin.json (manifeste plugin)"
  - ".claude-plugin/marketplace.json (entrée marketplace)"
  - "Doc d'install plugin 2-commandes + auto-lancement"
affects:
  - "README.md, INSTALL.md (section installation)"
tech-stack:
  added: []
  patterns:
    - "Plugin Claude Code : skills via champ skills, hooks via champ hooks (pas de skills/ racine)"
    - "Cache câblé sur ${CLAUDE_PLUGIN_ROOT} avec fallback dev repo"
key-files:
  created:
    - ".claude-plugin/plugin.json"
    - ".claude-plugin/marketplace.json"
  modified:
    - "installer/SKILL.md"
    - "README.md"
    - "INSTALL.md"
decisions:
  - "license = UNLICENSED (LICENSE proprietaire all-rights-reserved, PAS MIT comme supposé au plan)"
  - "Ajout d'une description racine au marketplace.json pour lever le warning claude plugin validate"
metrics:
  duration_min: 2
  completed: "2026-06-04"
  tasks: 3
  files: 5
---

# Phase 5 Plan 01 : Packaging plugin VibeFlow Summary

Transformation de `vibeflow-os` en plugin Claude Code installable via marketplace : deux manifestes valides calqués sur Superpowers, cache du skill câblé sur `${CLAUDE_PLUGIN_ROOT}` (fallback dev), hook SessionStart vérifié résolvable au runtime, et doc d'install réécrite en flux 2-commandes + auto-lancement.

## Tasks réalisées

| Task | Nom | Commit | Fichiers |
|------|-----|--------|----------|
| 1 | Manifestes plugin + vérif hook (PLUG-01) | `26e55b8` | .claude-plugin/plugin.json, .claude-plugin/marketplace.json |
| 2 | Câblage VIBEFLOW_CACHE=${CLAUDE_PLUGIN_ROOT} (PLUG-02) | `9b8b199` | installer/SKILL.md |
| 3 | Doc install plugin 2-commandes + auto-lancement (PLUG-02) | `b8da662` | README.md, INSTALL.md |

## Vérification

- `jq empty` : plugin.json + marketplace.json + hooks.json → tous JSON valides.
- `claude plugin validate .` → **Validation passed** (sans warning après ajout description marketplace).
- plugin.json : `name=vibeflow`, `version=2.3.0`, `skills=./installer`, `hooks=./installer/hooks/hooks.json`.
- marketplace.json : entrée `vibeflow`, `source=./`, `category=development`.
- **SMOKE TEST runtime du hook** : `${CLAUDE_PLUGIN_ROOT}` résolu sur la racine repo → `installer/hooks/session-start` existe + exécutable ; exécuté en HOME/CWD temporaire (mktemp), émet un JSON dont `additionalContext` contient `vibeflow-install`. Le vrai `~/.claude` n'est pas touché.
- installer/SKILL.md : frontmatter `name: vibeflow-install` présent ; 10 occurrences hors-commentaire de `CLAUDE_PLUGIN_ROOT` ; fallback dev + mention `resolve-deps` présents. Scripts `.sh` non modifiés.
- `_internal/resolve-deps.sh` présent dans le bundle (--with-deps fonctionne après install).
- Aucun dossier `skills/` à la racine → pas de double-chargement (T-05-04 neutralisé).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] license = UNLICENSED, pas MIT**
- **Found during:** Task 1
- **Issue:** Le plan supposait une licence MIT « probable ». Le fichier `LICENSE` est en réalité proprietaire (« Copyright (c) 2026 picmakpro / All rights reserved »).
- **Fix:** Utilisé l'identifiant `"UNLICENSED"` (convention proprietaire), conforme à la source de vérité LICENSE plutôt qu'à l'hypothèse du plan.
- **Files modified:** .claude-plugin/plugin.json
- **Commit:** `26e55b8`

**2. [Rule 2 - Missing] description racine du marketplace.json**
- **Found during:** Task 1 (verify `claude plugin validate`)
- **Issue:** `claude plugin validate` émettait un warning « No marketplace description provided ».
- **Fix:** Ajouté un champ `description` à la racine de marketplace.json → validation 100% propre.
- **Files modified:** .claude-plugin/marketplace.json
- **Commit:** `26e55b8`

### Écarts informatifs (pas de correction nécessaire)

- **hooks.json déjà corrigé** : la Task 1 (A) prévoyait de corriger le chemin du hook si nécessaire. Le fichier `installer/hooks/hooks.json` pointait déjà sur `installer/hooks/session-start` (corrigé par le commit pre-plan `33c2d27`). Aucune modification requise — le smoke test runtime confirme la résolution. hooks.json n'est donc pas dans les commits de ce plan.

## Auth gates

Aucun.

## Known Stubs

Aucun stub introduit.

## Threat Flags

Aucune nouvelle surface de menace hors threat_model du plan.

## Self-Check: PASSED

- FOUND: .claude-plugin/plugin.json
- FOUND: .claude-plugin/marketplace.json
- FOUND: installer/SKILL.md (modifié)
- FOUND: README.md (modifié)
- FOUND: INSTALL.md (modifié)
- FOUND commit: 26e55b8
- FOUND commit: 9b8b199
- FOUND commit: b8da662
