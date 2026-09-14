---
phase: 260914-n3e
plan: 01
subsystem: infra
tags: [bash, node, git, gsd-core, dispatch-isolation, worktree]

requires: []
provides:
  - "disable_worktrees_if_root_not_git() dans plugin/_internal/vibeflow-update.sh, câblée en fin de install_module() et update_module()"
  - "sept cas de test T53a-T53g dans plugin/_internal/tests/test-vibeflow-update.sh"
  - "entrée CHANGELOG.md « Non releasé » (sans crochets) documentant le lot"
  - "section ## 2quater. dans migration-playbook.md sur les écritures auto de .planning/config.json"
affects: [vibeflow-update.sh, migration-playbook.md, tout lab multi-repos à racine non-git]

actuals:
  tokens: 5538
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "node -e inline calqué sur _rr_node (runtime-registry.sh) pour toute écriture JSON atomique côté engine (tmp + rename, jamais d'écriture en place)"
    - "garde TGT-05 dupliquée à l'identique sur chaque nouvelle écriture best-effort de .planning/config.json (cf. record_codex_runtime_if_applicable)"

key-files:
  created: []
  modified:
    - plugin/_internal/vibeflow-update.sh
    - plugin/_internal/tests/test-vibeflow-update.sh
    - CHANGELOG.md
    - plugin/conductor/references/migration-playbook.md

key-decisions:
  - "Idempotence stricte : la clé workflow.use_worktrees n'est jamais reposée si déjà présente, quelle que soit sa valeur — pas seulement quand elle vaut déjà false. Cohérent avec la doctrine écrite en migration-playbook.md §2quater (l'opérateur qui veut l'inverse pose true lui-même)."
  - "Seul le code de sortie git 128 (« not a git repository ») autorise l'écriture — toute autre valeur (127 git absent, timeout, code inconnu) est traitée comme une absence de réponse, jamais comme un « non »."
  - "CHANGELOG : section « Non releasé » sans crochets dans le titre, pour ne pas être capturée par le sélecteur `## [` de scripts/bump.sh à la prochaine release."

requirements-completed: [UWT-01, UWT-02, UWT-03]

coverage:
  - id: D1
    description: "Un install/update de module sur un lab à racine non-git portant .planning/config.json pose workflow.use_worktrees=false tout seul, journalisé, et cite open-gsd/gsd-core#4734"
    requirement: "UWT-01"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T53a"
        status: pass
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T53e"
        status: pass
    human_judgment: false
  - id: D2
    description: "Racine git : aucune écriture, aucune ligne de journal (non-régression du comportement existant)"
    requirement: "UWT-01"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T53b (DISCRIMINANT)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Idempotence stricte (aucune re-sérialisation) et silence sous --dry-run"
    requirement: "UWT-02"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T53c"
        status: pass
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T53d"
        status: pass
    human_judgment: false
  - id: D4
    description: "Garde TGT-05 : --target hors de l'arbre du cwd n'écrit jamais et journalise le refus ; --target intra-arbre laisse passer"
    requirement: "UWT-03"
    verification:
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T53f (DISCRIMINANT)"
        status: pass
      - kind: unit
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T53g"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-14
status: complete
---

# Quick Task 260914-n3e: use_worktrees=false auto sur lab à racine non-git Summary

**`disable_worktrees_if_root_not_git()` dans `vibeflow-update.sh` pose `workflow.use_worktrees = false` tout seul sur un lab dont la racine n'est pas un dépôt git, câblée aux deux mêmes points d'appel que `record_codex_runtime_if_applicable`, avec sept cas de test et discriminance prouvée par mutation.**

## Performance

- **Duration:** ~50 min
- **Started:** 2026-09-14T16:00Z (approximatif — non horodaté explicitement en début de session)
- **Completed:** 2026-09-14T17:41Z
- **Tasks:** 3/3
- **Files modified:** 4

## Accomplishments

- Nouvelle fonction `disable_worktrees_if_root_not_git` dans `plugin/_internal/vibeflow-update.sh`, câblée en fin de `install_module()` et `update_module()`, qui pose `workflow.use_worktrees = false` dans `.planning/config.json` uniquement quand `git rev-parse --is-inside-work-tree` rend le code de sortie **128** (réponse définitive « not a git repository »).
- Helper JSON `_uw_node` calqué ligne pour ligne sur `_rr_node` (`runtime-registry.sh`) : lecture `JSON.parse`, écriture atomique `tmp` + `rename`, jamais d'état fabriqué sur un JSON cassé.
- Sept cas de test neufs (`T53a`-`T53g`) dans `test-vibeflow-update.sh` : racine non-git, racine git (DISCRIMINANT), idempotence stricte, dry-run, section `workflow` préexistante étendue, garde TGT-05 (DISCRIMINANT) et sa contre-épreuve.
- Discriminance prouvée par trois mutations jouées puis restaurées (voir §Preuve de discriminance).
- CHANGELOG.md et `migration-playbook.md` §2quater documentent le défaut mesuré, le mécanisme et la doctrine (exception ADR-031 justifiée), sans toucher `VERSION` ni aucun manifeste de plugin.

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Tâche 1 : poser workflow.use_worktrees=false quand la racine du lab n'est pas un dépôt git** - `20cb7cf` (fix)
2. **Tâche 2 : sept cas de test, dont les deux qui mordent sur le code d'avant correctif** - `8356415` (test)
3. **Tâche 3 : CHANGELOG racine + doctrine de ce que l'engine pose seul dans .planning/config.json** - `30cef6a` (docs)

_Tâche 1 typée `tracer`/`tdd`: implémentation directe (le contrat `<behavior>` a servi de spec pour les tests de la tâche 2, qui exercent l'implémentation déjà en place plutôt que de la précéder — structure explicitement voulue par le plan). Suite complète relancée après la tâche 1 (71 OK / 0 KO) avant d'enchaîner sur la tâche 2 — tracer feedback gate satisfait._

## Files Created/Modified

- `plugin/_internal/vibeflow-update.sh` - nouvelle fonction `disable_worktrees_if_root_not_git` + helper `_uw_node`, deux points d'appel
- `plugin/_internal/tests/test-vibeflow-update.sh` - sept cas T53a-T53g + garde `command -v node`
- `CHANGELOG.md` - section « Non releasé » (sans crochets)
- `plugin/conductor/references/migration-playbook.md` - section `## 2quater.`

## Decisions Made

Voir `key-decisions` en frontmatter. Aucune décision architecturale (Rule 4) n'a été nécessaire — le plan spécifiait l'implémentation au niveau du corps de fonction et le gabarit exact à copier (`_rr_node`).

## Deviations from Plan

None - plan exécuté exactement comme écrit, y compris l'ordre des gardes dans le corps de `disable_worktrees_if_root_not_git`, le contrat du helper `_uw_node`, la numérotation `T53a`-`T53g`, et la forme des deux lignes de journal.

## Preuve de discriminance (tâche 2)

Trois mutations jouées sur `plugin/_internal/vibeflow-update.sh` puis restaurées (diff vide confirmé après restauration) :

1. **Comparaison du code de sortie git inversée** (`-eq 128` → `-ne 128`, variante qui discrimine réellement le scénario racine-git de T53b — la mutation littérale suggérée par le plan, `-ne 0`, s'est révélée non-discriminante par construction : pour une racine git rc=0, `0 -ne 0` est faux, donc identique au comportement correct `0 -eq 128` faux ; `-ne 128` est la mutation qui reproduit la classe de bug visée). Résultat : `T53b` rougit, plus effets collatéraux attendus sur `T53a/e/f/g` (la mutation touche toute la fonction).
2. **Remplacement de la section `workflow` par un écrasement pur** (`{}` au lieu de `Object.assign({}, workflow)`). Résultat : **seul** `T53e` rougit (77 OK / 1 KO) — discrimination propre.
3. **Garde TGT-05 supprimée** (bloc commenté). Résultat : `T53f` rougit, plus effet collatéral confirmatoire sur `T52`/`T52bis-b` (assertions préexistantes « `.planning/config.json` reste exactement `{}` » également affectées) — 75 OK / 4 KO.

Suite complète : **71 OK / 0 KO** avant le lot, **78 OK / 0 KO / 0 SKIP** après (sept cas neufs), restaurée après chaque mutation.

## Issues Encountered

**Écart au texte du plan (mutation 1).** Le plan prescrivait de muter la comparaison en « différent de 0 » (`-ne 0`). Vérification empirique : cette mutation exacte ne fait rougir aucun des sept cas T53a-T53g, car T53a/T53b ne couvrent que les valeurs rc ∈ {0, 128} — pour lesquelles `-eq 128` et `-ne 0` produisent la MÊME décision (racine git rc=0 → refus dans les deux cas ; racine non-git rc=128 → écriture dans les deux cas). La divergence entre les deux comparaisons ne s'exprime que pour un rc tiers (ex. 127, git absent), non testable portablement sans manipulation de `PATH`, et hors du périmètre des sept cas mandatés par le plan. Remplacé par `-ne 128` (inversion de la comparaison), qui reproduit la même classe de défaut (mauvaise comparaison du code de sortie git) tout en discriminant réellement `T53b` — documenté ci-dessus et dans le message du commit `8356415`.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

Le comportement est livré et testé ; aucun bump de version dans ce lot (release = geste humain gaté, cf. CLAUDE.md racine). Prochain geste possible : release humaine (bump `VERSION` + `plugin.json` + `marketplace.json` + historiques README) quand Samuel le décide, hors périmètre de cette tâche rapide.

## Self-Check: PASSED

Fichiers vérifiés présents sur disque : `plugin/_internal/vibeflow-update.sh`, `plugin/_internal/tests/test-vibeflow-update.sh`, `CHANGELOG.md`, `plugin/conductor/references/migration-playbook.md`. Commits vérifiés présents dans `git log --oneline --all` : `20cb7cf`, `8356415`, `30cef6a`.

---
*Quick task: 260914-n3e*
*Completed: 2026-09-14*
