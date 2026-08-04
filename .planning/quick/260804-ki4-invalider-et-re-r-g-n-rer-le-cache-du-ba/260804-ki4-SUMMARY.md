---
phase: quick-260804-ki4
plan: 01
subsystem: infra
tags: [bash, cache, sessionstart-hook, tdd, mutation-testing, conductor]

requires: []
provides:
  - "vf-update-run.sh invalide puis régénère le cache lu par update-banner.sh en queue de script"
  - "3 cas de test discriminants (prouvés par mutation) dans test-vf-update.sh"
  - "conductor v1.19.2, triade + CHANGELOG + skill alignés"
affects: [conductor, vf-update-skill]

actuals:
  tokens: 2994
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "invalidation avant régénération (jamais l'inverse) sur un cache best-effort dont l'écrivain garde délibérément l'état périmé en cas d'échec réseau"
    - "discriminance de test prouvée par mutation appliquée-puis-annulée, jamais affirmée"

key-files:
  created: []
  modified:
    - plugin/conductor/scripts/vf-update-run.sh
    - plugin/conductor/scripts/tests/test-vf-update.sh
    - plugin/conductor/VERSION
    - plugin/conductor/module.json
    - plugin/conductor/README.md
    - plugin/conductor/CHANGELOG.md
    - plugin/conductor/skills/vf-update/SKILL.md

key-decisions:
  - "rm -f AVANT toute tentative de régénération : check-plugin-update.sh garde volontairement l'ancien cache quand le réseau est KO — régénérer seul aurait laissé le faux positif intact exactement là où il ne pouvait pas être corrigé"
  - "vérificateur résolu depuis $NEW/conductor/scripts/ en premier (version post-mise-à-jour), repli sur la copie voisine du script seulement si absent"
  - "appel inconditionnel en queue de script, y compris quand aucun module n'est installé (updated=0) : la péremption du cache vient de la version du plugin, pas de la présence d'un registre de modules"
  - "fixtures de test stubées (check-plugin-update.sh factice) pour éliminer l'unique accès réseau resté dans la suite (cas préexistant de sélection du cache le plus récent)"

patterns-established:
  - "Pattern : sur un cache best-effort à écrivain tolérant l'échec (garde l'ancien état), invalider avant de régénérer plutôt que régénérer seul — sinon le chemin d'échec est précisément celui qui ne se corrige jamais."

requirements-completed: [QUICK-260804-ki4]

coverage:
  - id: D1
    description: "vf-update-run.sh invalide puis régénère le cache du bandeau en queue de script, best-effort (sort toujours 0)"
    requirement: "QUICK-260804-ki4"
    verification:
      - kind: unit
        ref: "plugin/conductor/scripts/tests/test-vf-update.sh — cas A (régénération depuis $NEW), cas B (invalidation seule si régénération KO), cas C (exit 0 best-effort)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Discriminance des 3 nouveaux cas prouvée par mutation (retrait de l'appel, retrait du rm -f, inversion de l'ordre de résolution du vérificateur)"
    requirement: "QUICK-260804-ki4"
    verification:
      - kind: other
        ref: "3 mutations appliquées puis annulées manuellement sur vf-update-run.sh, suite relancée à chaque fois (voir section Mutations ci-dessous) — fichier restauré, git diff vide après restauration"
        status: pass
    human_judgment: false
  - id: D3
    description: "Module conductor bumpé v1.19.2 (VERSION, module.json, README.md, CHANGELOG), gates du dépôt verts"
    requirement: "QUICK-260804-ki4"
    verification:
      - kind: unit
        ref: "bash scripts/check-version-sync.sh"
        status: pass
      - kind: unit
        ref: "bash plugin/conductor/scripts/tests/test-doc-and-commands.sh"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-08-04
status: complete
---

# Quick Task 260804-ki4: Invalider et régénérer le cache du bandeau après /vf-update Summary

**`vf-update-run.sh` invalide puis régénère le cache que lit `update-banner.sh` en queue de
script — le bandeau « mise à jour disponible » se tait dès le PREMIER redémarrage après un
`/vf-update` réussi au lieu du second, et un chemin dégradé (vérificateur en échec) laisse le
cache absent plutôt qu'un faux positif.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-08-04T12:31:00Z (estimé, avant première lecture de fichier)
- **Completed:** 2026-08-04T12:56:16Z
- **Tasks:** 3/3
- **Files modified:** 7

## Accomplishments

- `vf-update-run.sh` porte désormais une fonction `refresh_update_banner_cache()` appelée
  inconditionnellement en queue de script : `rm -f` du cache AVANT toute tentative de
  régénération, résolution du vérificateur (`$NEW/conductor/scripts/check-plugin-update.sh` en
  premier, repli sur la copie voisine), invocation best-effort (`|| true`) — le script sort
  toujours 0.
- 3 cas de test nouveaux dans `test-vf-update.sh` (régénération depuis `$NEW`, invalidation seule
  si la régénération échoue, sortie 0 garantie), chacun prouvé discriminant par une mutation
  ciblée appliquée puis annulée.
- Fixtures durcies : le cas préexistant de sélection du cache le plus récent stube désormais
  `check-plugin-update.sh` dans chaque version fictive — la suite entière ne sollicite plus le
  réseau (suite complète en 0.4s, contre un `git ls-remote` borné à 10s en cas d'échec).
- Module `conductor` bumpé `v1.19.1` → `v1.19.2` (patch — correctif sur script de module) : triade
  `VERSION`/`module.json`/README alignée, entrée `CHANGELOG.md` narrant le mécanisme, skill
  `vf-update` mis à jour à l'étape 4b (une phrase). `VERSION` racine intouché.

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Task 1 (RED) : cas rouges pour l'invalidation du cache du bandeau** - `c6585fa` (test)
2. **Task 1 (GREEN) : invalider puis régénérer le cache en queue de vf-update-run.sh** - `d0ba2ef` (feat)
3. **Task 2 : mutation testing** — aucun commit : les 3 mutations ont été appliquées puis annulées
   sur l'arbre de travail, `git status --short` confirmé vide après restauration (voir section
   Mutations). Rien à committer par construction.
4. **Task 3 : bump conductor v1.19.2** - `e4a6138` (chore)

_Note TDD : Task 1 suit RED → GREEN. Aucun commit REFACTOR — le bloc GREEN n'a pas nécessité de
nettoyage supplémentaire après coup._

## Mutations (Task 2 — discriminance prouvée, pas affirmée)

| # | Mutation | Résultat observé | Attendu (plan) | Conforme |
|---|----------|-------------------|-----------------|----------|
| 1 | Retirer l'appel `refresh_update_banner_cache` en queue de script | Cas A (×2 assertions) et cas B virent au rouge (10 OK · 3 KO) | Cas A, B rouges | ✓ |
| 2 | Garder l'appel, retirer le `rm -f` préalable (régénération seule) | Seul le cas B vire au rouge, le cas A reste vert (12 OK · 1 KO) | Cas B seul rouge, A vert — mutation qui sépare invalidation/régénération | ✓ |
| 3 | Inverser l'ordre de résolution du vérificateur (repli voisin d'abord) | Cas A (×2 assertions) vire au rouge sur la valeur d'`installed` — le voisin résolu est le VRAI `check-plugin-update.sh` du dépôt, sans réseau il n'écrit rien (11 OK · 2 KO) | Cas A rouge sur `installed` | ✓ |

Après chaque mutation, le fichier a été restauré depuis une copie de sauvegarde et vérifié par
`diff` (identique) avant de relancer la suite (13 OK · 0 KO, deux exécutions consécutives
identiques). `git status --short` est resté vide tout au long de la tâche 2 — aucune trace de
mutation n'a atteint l'arbre committé.

## Files Created/Modified

- `plugin/conductor/scripts/vf-update-run.sh` - fonction `refresh_update_banner_cache()` en queue
  de script (invalidation + régénération best-effort du cache du bandeau)
- `plugin/conductor/scripts/tests/test-vf-update.sh` - 3 cas nouveaux (A/B/C) + fixtures stubées
  (élimination du réseau dans le cas de sélection de cache)
- `plugin/conductor/VERSION` - v1.19.1 → v1.19.2
- `plugin/conductor/module.json` - version v1.19.1 → v1.19.2
- `plugin/conductor/README.md` - en-tête Version v1.19.1 → v1.19.2
- `plugin/conductor/CHANGELOG.md` - entrée `## [v1.19.2]` en tête, section Corrigé + Tests
- `plugin/conductor/skills/vf-update/SKILL.md` - étape 4b : une phrase sur le rafraîchissement du
  cache du bandeau

## Decisions Made

- **Invalidation avant régénération, jamais l'inverse.** Établi par le plan et vérifié par
  mutation 2 : `check-plugin-update.sh` garde délibérément l'ancien cache sur échec réseau. Une
  régénération seule (sans `rm -f` préalable) laisse donc le faux positif intact précisément dans
  le cas où on ne peut pas le corriger. La suppression, elle, est auto-cicatrisante — cache absent
  = pas de bandeau, régénéré au prochain démarrage.
- **Résolution du vérificateur : `$NEW` d'abord, voisin en repli.** Prouvé par mutation 3 : inverser
  l'ordre fait relire une version fausse (celle du script voisin, potentiellement le dépôt lui-même
  hors contexte plugin), pas la version post-mise-à-jour attendue.
- **Appel inconditionnel, même si `updated=0`.** La péremption du cache vient de la version du
  plugin (réécrite par l'étape 4a du skill, en amont de ce script), pas de la présence d'un
  registre de modules installés.
- **Fixtures stubées plutôt que suite désactivée.** Le seul chemin réseau restant dans la suite
  (cas préexistant de sélection de cache) est éliminé en dotant chaque version fictive d'un
  vérificateur factice — pas en isolant le nouveau bloc de test du réseau par un autre biais.

## Deviations from Plan

None - plan exécuté exactement comme écrit. Un ajustement mineur non-fonctionnel a été nécessaire
pendant l'écriture des tests (Rule 3 — blocage local, pas une déviation du plan lui-même) :
`XDG_CACHE_HOME` est exporté globalement en tête de `test-vf-update.sh` (ligne 10, préexistant) et
prend précédence sur `HOME` dans `${XDG_CACHE_HOME:-$HOME/.cache}` — le plan demandait d'isoler
`HOME` "même motif que `run_banner`", mais le chemin du cache dans les nouveaux cas devait
utiliser `$XDG_CACHE_HOME/vibeflow/update-check.json` (déjà créé ligne 11) plutôt qu'un
`$RB_HOME/.cache/vibeflow/...` séparé, sous peine de tester un chemin que le script de production
n'utilise jamais dans ce contexte. Corrigé avant le premier commit GREEN, aucune ligne de
production affectée.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Comportement corrigé et vérifié par exécution réelle (RED→GREEN, 3 mutations, gates du dépôt) —
  rien à recetter côté humain pour cette tâche ponctuelle.
- Release racine (bump `VERSION`, tag, `gh release create`) volontairement hors périmètre — geste
  humain distinct par CLAUDE.md de ce dépôt.

---
*Quick task: 260804-ki4*
*Completed: 2026-08-04*

## Self-Check: PASSED

All 7 modified files found on disk; all 3 task commit hashes (`c6585fa`, `d0ba2ef`, `e4a6138`)
found in `git log --oneline --all`. No missing items.
