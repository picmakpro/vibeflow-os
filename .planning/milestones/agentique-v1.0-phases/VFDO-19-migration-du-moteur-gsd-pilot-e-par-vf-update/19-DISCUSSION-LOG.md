# Phase 19 — Journal de discussion

**Date :** 2026-07-28
**Mode :** interactif (`AskUserQuestion`), 6 questions en 2 tours
**Portée :** référence humaine (audit, rétrospective) — **non consommé** par les agents aval
(researcher, planner, executor), qui lisent `19-CONTEXT.md`.

## Avant discussion — vérification des constats

Les 5 trous du rapport `.planning/missions/2026-07-28-audit-externe-migration-opengsd.md` ont été
recoupés dans le repo **avant** d'ouvrir la phase. Verdict : 5/5 confirmés, avec 2 nuances.

| Trou | Verdict | Preuve |
|---|---|---|
| 1 — `/vf-update` ne touche pas au moteur | Confirmé, mais **choix écrit** | `vf-update/SKILL.md` §Garde-fous : « hors périmètre de ce skill ». Donc doctrine à réviser (ADR), pas patch. |
| 2 — early-return sur le legacy | Confirmé **à la ligne** | `ensure-deps.sh:119-120` (`||`) et `:133` (`skip`). |
| 3 — signal de nettoyage inatteignable | Confirmé | `log_legacy_cleanup_if_needed()` (`:184`) appelé seulement depuis `ensure_gsd()`. Les 3 hooks `SessionStart` de dev-orchestrator ne regardent jamais le moteur. |
| 4 — `1.8.0 < 1.42.3` | Confirmé comme **piège**, pas comme bug actuel | `check-plugin-update.sh:66-73` ne compare que les tags GitHub du plugin. Aucun comparateur en défaut aujourd'hui. |
| 5 — injection MCP défaite | Confirmé structurellement | `patch_gsd_executor_mcp` n'existe que dans `ensure-deps.sh` ; `vibeflow-update.sh:268` n'injecte que sur les agents flaggés `vf-mcp-consumer`, flag absent de `gsd-executor`. |

Le point 5 du « ce que je veux » est également juste : `test-gsd-cohabitation.sh` ne teste que le
merger `settings.json` (en-tête ligne 2).

## Tour 0 — cadrage du périmètre (avant ouverture de la phase)

**Ambition de `/vf-update` sur le moteur** — options : détecter+proposer / détecter+dire seulement /
détecter+proposer+hook de démarrage.
→ **Détecter + proposer** (le « au mieux » du rapport). Le hook de démarrage est écarté.

**Périmètre de la phase** (multi-select, 4 options) → **les 4 retenues** : trous 1+2 (détecteur +
branchement), trou 5 (ré-injection MCP), trou 3 (message de nettoyage), trou 4 (tests de
non-régression).

## Tour 1 — quatre zones grises

**1. Ancrage du détecteur.** Contexte donné : `dev-orchestrator` requiert `conductor`, jamais
l'inverse, et `conductor` est le seul module `mandatory` — or `ensure-deps.sh` est dans
dev-orchestrator et `vf-update` dans conductor.
Options : script dédié + sonde best-effort / fonction élargie dans `ensure-deps.sh` / détecteur dans
conductor.
→ **Script dédié `check-gsd-engine.sh` + sonde best-effort.** Un lab non-dev ne voit jamais rien.

**2. Exécution de la migration.** Options : `ensure-deps.sh --migrate-engine` / idem + sauvegarde
`tar` / le skill lance `npx` lui-même.
→ **`ensure-deps.sh --migrate-engine`**, sans sauvegarde `tar`. Point de vérité unique, la
ré-injection MCP ne peut pas être oubliée. Le `tar` est noté en idée reportée.

**3. Vérification de la ré-injection MCP.** Options : mode `--verify` sur `inject-mcp-tools.sh` /
vérification inline dans `ensure-deps.sh` / aucune (l'idempotence suffit).
→ **Mode `--verify`.** Réutilisable hors migration, testable dans une suite qui existe déjà.

**4. Nettoyage du legacy.** Options : proposer jamais exécuter / proposer dans la même confirmation
/ se taire si l'arbre est vide.
→ **Proposer, jamais exécuter** (ADR-031 strict). Aucun `rm -rf` ni `npm uninstall` exécuté par
VibeFlow.

## Tour 2 — deux points que le tour 1 n'avait pas couverts

**5. Le stop de l'étape 1.** Constat soulevé pendant la discussion : sur le poste audité le plugin
était **déjà à jour**, donc `/vf-update` s'arrêtait sur `update_available = false` **avant** toute
détection du moteur — la phase n'aurait rien corrigé.
Options : détecter le moteur avant le stop / stop maintenu + ligne informative / deux stops
distincts.
→ **Détecter le moteur AVANT le stop.** L'étape 1 devient un diagnostic à deux volets.

**6. Emplacement du test du scénario réel.** Options : suite dédiée au nouveau gate / étendre
`test-gsd-cohabitation.sh` / les deux.
→ **Suite dédiée** `test-check-gsd-engine.sh`. Motif retenu : `test-gsd-cohabitation.sh` porte le
merger `settings.json` de l'engine, pas un gate de dev-orchestrator — c'est justement parce qu'il ne
testait que le merger que le trou n'a pas été vu en v2.39.0.

## Tranché sans question (implémentation, non soumis)

- **Cas dual** (les deux layouts présents) → état `gsd-core`, plus un signal de reliquat.
  Reproposer une install serait un no-op bruyant.
- **Flags existants du skill** : `--check` affiche l'état du moteur sans rien demander ;
  `--modules-only` ne propose pas la migration (son nom borne son périmètre). Aucun `--engine-only`
  créé — densité ADR-029.
- **Piège de séquencement du message de nettoyage** : l'installeur amont supprime le `VERSION`
  legacy, donc l'état doit être **capturé avant l'install**, pas re-détecté après.

## Idées reportées

- Hook `SessionStart` sur l'état du moteur (écarté par Samuel).
- Sauvegarde `tar` avant migration (écartée).
- Le hook `gsd-check-update` du moteur legacy — code amont, RFC `open-gsd/gsd-core` si confirmé.
- Passe transverse « qui appelle ce script en régime nominal ? » — sa propre phase.
- Second rapport d'audit (fluidité, 4 changements) — non instruit, à arbitrer après.
- Clés `gates` / `safety` orphelines dans `.planning/config.json`, rejetées par `gsd-tools` 1.8.0.

---

*Phase: 19 — Migration du moteur GSD pilotée par /vf-update*
