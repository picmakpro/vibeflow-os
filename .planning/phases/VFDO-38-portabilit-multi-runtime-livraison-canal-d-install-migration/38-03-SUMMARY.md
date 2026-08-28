---
phase: 38-portabilit-multi-runtime-livraison-canal-d-install-migration
plan: 03
subsystem: infra
tags: [bash, vibeflow-update, rollback, backup, hooks]

requires:
  - phase: 38-02
    provides: engine multi-runtime commun (partage vibeflow-update.sh)
provides:
  - "rollback_module() restaure agents/${mod}.md + agents/${mod}-references/ + hooks, symétrique de backup_module()"
  - "backup_module() capture la version installée au moment du backup ($bdir/.version) et le fragment hooks du cache courant"
  - "merge_module_hooks()/remove_module_hooks() acceptent un 2e paramètre optionnel fragment_override"
  - "rollback échoue bruyamment sur un backup sans sous-dossier restaurable (fini le rollback silencieux no-op qui loggait OK)"
  - "--dry-run rollback fonctionnel (prévisualisation, aucune écriture)"
affects: [38-04, 38-05, 38-06]

actuals:
  tokens: 78000
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Capture de version au backup ($bdir/.version) plutôt qu'une version devinée à la restauration"
    - "Filtrage post-liste du glob de backup (grep -v -- '-removed$') plutôt qu'une modification du glob lui-même"

key-files:
  created: []
  modified:
    - plugin/_internal/vibeflow-update.sh
    - plugin/_internal/tests/test-vibeflow-update.sh

key-decisions:
  - "VERSION/CHANGELOG de plugin/conductor NON bumpés malgré files_modified du plan : le mandat de dispatch interdit explicitement plugin/conductor/** (écriture concurrente d'un autre worker, FIDE). Conflit plan vs mandat remonté au manager plutôt que tranché seul — voir bloc typé."
  - "merge_module_hooks()/remove_module_hooks() : paramètre optionnel fragment_override (\"${2:-\\$CACHE_DIR/\\$mod/hooks/hooks.json}\") plutôt qu'une signature neuve — les ~6 appelants existants retombent sur le comportement exact d'avant ce lot."
  - "Filtrage du backup sélectionné : grep -v -- '-removed$' en POST-liste du ls -1dt existant, jamais une modification du glob source (le glob doit continuer à matcher les deux formes, conforme à la prohibition du plan)."

requirements-completed: [ROLL-01, ROLL-02, ROLL-03, ROLL-04, ROLL-05]

coverage:
  - id: D1
    description: "rollback_module() restaure symétriquement tout ce que backup_module() sauvegarde (skills, scripts, agents/${mod}.md, agents/${mod}-references/, hooks/hooks.json)"
    requirement: "ROLL-01"
    verification:
      - kind: integration
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T13,T15"
        status: pass
    human_judgment: false
  - id: D2
    description: "rollback réinjecte le fragment hooks SAUVEGARDÉ au backup, pas le fragment courant du cache au moment du rollback"
    requirement: "ROLL-02"
    verification:
      - kind: integration
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T18,T19"
        status: pass
    human_judgment: false
  - id: D3
    description: "le registre (.vibeflow-installed) est remis à la version capturée au backup après rollback, jamais laissé à la version neuve effacée"
    requirement: "ROLL-03"
    verification:
      - kind: integration
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T14,T15"
        status: pass
    human_judgment: false
  - id: D4
    description: "un rollback sans backup restaurable (aucun, ou uniquement des répertoires -removed de convergence) échoue bruyamment, jamais un OK sur zéro action"
    requirement: "ROLL-04"
    verification:
      - kind: integration
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T16,T17"
        status: pass
    human_judgment: false
  - id: D5
    description: "--dry-run rollback <module> prévisualise sans écrire sur disque"
    requirement: "ROLL-05"
    verification:
      - kind: integration
        ref: "plugin/_internal/tests/test-vibeflow-update.sh#T20"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-08-28
status: complete
---

# Phase 38 Plan 03: Le trou de `rollback` — Summary

**`rollback_module()` restaure désormais agents+agent-references+hooks (plus skills+scripts déjà
existants), remet le registre à la version capturée au backup, refuse bruyamment un backup de
convergence vide, et `--dry-run rollback` fonctionne — fermant le mode d'échec dominant mesuré au
cadrage (rollback silencieux no-op qui loggait `✓ rollback OK` sur zéro action réelle).**

## Performance

- **Tasks:** 2
- **Files modified:** 2 (`plugin/_internal/vibeflow-update.sh`, `plugin/_internal/tests/test-vibeflow-update.sh`)
- **Commits:** 1 (voir Deviations — split par tâche non fait, fonctions trop imbriquées pour un
  découpage propre sans état intermédiaire incohérent)

## Accomplishments

- `backup_module()` capture la version installée AU MOMENT du backup (`$bdir/.version`, grep+cut
  sur `$INSTALLED_REGISTRY`) et le fragment `hooks/hooks.json` du cache courant.
- `rollback_module()` restaure `agents/${mod}.md` + `agents/${mod}-references/` (déjà sauvegardés
  par `backup_module()` depuis D7, jamais relus jusqu'à ce lot) et les hooks (retrait du fragment
  courant via `remove_module_hooks`, réinjection du fragment sauvegardé via `merge_module_hooks`
  avec son 2e paramètre neuf).
- Le glob de sélection du backup (`ls -1dt "$BACKUP_DIR/$mod"-*`) est filtré en POST-liste
  (`grep -v -- '-removed$'`) pour exclure les répertoires de convergence `vf_converge_apply` — le
  `rm -rf` n'était jamais atteint sur ces répertoires (aucun sous-dossier `skills/`), et la
  fonction annonçait quand même `✓ rollback OK`. Le cas est désormais un échec bruyant.
- `mark_installed "$mod" "$version_capturée"` appelé après restauration réussie — le registre ne
  ment plus après un rollback.
- `--dry-run` accepte `rollback` (garde ligne ~98-103 étendue), `rollback_module()` court-circuite
  en tête via `vf_dry_run()` (prédicat existant, pas de nouveau flag) et imprime une prévisualisation.

## Preuve du scénario v1 → v2 → rollback → v1 (T15, `plugin/_internal/tests/test-vibeflow-update.sh`)

Fixture réelle (`mktemp -d`), module `rollmod` avec `skills/rollmod/SKILL.md`, `AGENT.md`,
`references/note.md`, contenu DISTINGUABLE par version (marqueurs `MARKER-V1`/`MARKER-V2`) :

1. `install rollmod` (VERSION=v1.0.0) → registre `rollmod=v1.0.0`.
2. Cache bumpé à v2.0.0, contenu changé (marqueurs v2). `install rollmod` à nouveau → déclenche
   `backup_module` (module déjà installé) : capture skills/agents/agent-references v1 + `.version=v1.0.0`.
   Registre → `rollmod=v2.0.0`. Disque porte désormais le contenu v2 (vérifié en pré-condition du
   test).
3. `rollback rollmod` → assertions RÉELLES post-restauration :
   - `[ -f .claude/skills/rollmod/SKILL.md ]`, `[ -f .claude/agents/rollmod.md ]`,
     `[ -d .claude/agents/rollmod-references ]` : présents.
   - `grep -q MARKER-V1 .claude/agents/rollmod.md` : vrai (contenu v1 restauré).
   - `grep -q MARKER-V2 .claude/agents/rollmod.md` : faux (contenu v2 remplacé, pas juste co-présent).
   - `grep '^rollmod=' .claude/scripts/.vibeflow-installed` = `v1.0.0` (≠ `v2.0.0` installé juste
     avant le rollback).

Résultat : `✓ T15 (ROLL-01..04 round-trip) : install v1 -> install v2 -> rollback -> contenu ET
registre restaurés à v1 (v1=v1.0.0, v2=v2.0.0)`.

## Preuve de l'échec bruyant sur backup `-removed`-only (T16)

Fixture : `mkdir -p .claude/.backups/onlyremoved-20260101-000000-removed` (aucun sous-dossier).
`rollback onlyremoved` → `rc=1`, ET la sortie capturée ne contient AUCUNE ligne
`✓ onlyremoved rollback OK` (assertion par absence, `grep -q` négatif). C'est exactement le défaut
mesuré au cadrage (38-CONTEXT.md 216-234) : avant ce lot, ce même scénario aurait loggé
`✓ rollback OK` malgré `rm -rf`/`cp -r` jamais atteints (vérifié en rejouant la nouvelle suite
contre le code d'AVANT via `git stash` — 12 KO ciblés, dont T16, sur les défauts précis corrigés
par ce lot ; T13/T17 restaient déjà verts avant, cohérent avec D-31-09 §a/§b « déjà confirmés »).

## Task Commits

1 seul commit atomique (voir Deviations) :

1. **fix(38-03): rollback_module restaure agents+agent-references+hooks, registre à jour,
   --dry-run fonctionnel (ROLL-01..05)** — `f74fb73`

## Files Created/Modified

- `plugin/_internal/vibeflow-update.sh` — `backup_module()`, `rollback_module()`,
  `merge_module_hooks()`, `remove_module_hooks()`, garde `--dry-run` (ligne ~98-103).
- `plugin/_internal/tests/test-vibeflow-update.sh` — T13-T20 ajoutés (192 lignes).

## Decisions Made

- **VERSION/CHANGELOG de `plugin/conductor` NON bumpés.** Le `PLAN.md` (`files_modified`) les
  listait, mais le mandat de dispatch interdit explicitement `plugin/conductor/**` (un autre
  worker — lot FIDE — y écrivait `check-artifact-fidelity.sh`/`VERSION`/`CHANGELOG.md` en
  concurrence directe). Conflit plan-vs-mandat remonté au manager plutôt que tranché seul (voir
  bloc typé, `action: ask-user`).
- **1 seul commit, pas 2 par tâche.** Les tâches 1 et 2 du plan touchent les MÊMES fonctions
  (`backup_module`/`rollback_module`) sur des lignes imbriquées (hooks + dry-run insérés au
  milieu de la restauration skills/agents de la tâche 1) — un split aurait produit un commit
  intermédiaire avec une fonction incohérente (moitié restaurée, moitié non). Un seul commit
  cohérent, message documentant les 2 tâches séparément.
- **Fixture `rollmod` : Type 2 nested skill (`skills/rollmod/SKILL.md`), PAS de `SKILL.md`
  racine.** Un module avec `SKILL.md` racine route ses `references/` sous
  `skills/$mod/references/` (ligne ~1507 de l'engine), jamais `agents/$mod-references/`
  (ligne ~1515, qui exige explicitement l'ABSENCE de `SKILL.md` racine). Découvert en construisant
  la fixture T13 — sans ce layout, `agents/rollmod-references/` n'aurait jamais existé et T13/T15
  auraient été des faux négatifs muets.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Layout de fixture module corrigé (SKILL.md racine vs nested) avant écriture des tests**
- **Found during:** Rédaction de la fixture T13/T14/T15
- **Issue:** Un module avec `SKILL.md` à la racine ET `AGENT.md` route ses `references/` sous
  `skills/$mod/references/`, pas `agents/$mod-references/` (condition ligne ~1515 exige
  l'absence de `SKILL.md` racine) — le layout initialement prévu (SKILL.md racine) aurait rendu
  T13 vert à vide sur la catégorie `agent-references`.
- **Fix:** Fixture reconstruite en Type 2 (`skills/rollmod/SKILL.md`), pas de `SKILL.md` racine.
- **Files modified:** `plugin/_internal/tests/test-vibeflow-update.sh` (fixture uniquement, avant
  tout commit).
- **Verification:** T13 confirmé rouge sur le code d'avant (`git stash`), vert après.
- **Committed in:** `f74fb73` (seul commit de ce plan).

---

**Total deviations:** 1 auto-fixé (bug de fixture découvert en écriture, corrigé avant tout
commit — n'a jamais touché le code de production). **Impact :** aucun — correction de test
uniquement, le comportement de l'engine n'est pas affecté.

## Issues Encountered

Aucun blocage fonctionnel. Un point de conflit plan/mandat (VERSION/CHANGELOG conductor) — voir
Decisions Made et bloc typé de fin de rapport, remonté au manager sans être tranché seul.

## Non-régression (rejouée intégralement)

- `find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` = **69** (68 baseline + 1 suite
  neuve `plugin/conductor/scripts/tests/test-check-artifact-fidelity.sh` posée par le lot FIDE
  concurrent — **pas par ce lot**, qui n'ajoute aucun fichier de suite).
- Les **68** suites préexistantes rejouées individuellement : **68/68 rc=0**. La 69e
  (`test-check-artifact-fidelity.sh`, hors périmètre — `plugin/conductor/**` en écriture
  concurrente) volontairement NON exécutée par ce worker.
- `bash plugin/_internal/tests/test-vibeflow-update.sh` : **27 OK / 0 KO / 0 SKIP** (19 baseline +
  8 nouvelles : T13-T20).
- Suites voisines référençant `vibeflow-update.sh` en lecture (risque de fenêtre positionnelle
  `grep -A<n>` mentionné au mandat, cf. Phase 31) rejouées individuellement, toutes vertes :
  `test-manifest.sh` (62/0), `test-merge-hooks.sh` (36/0), `test-vf-portable.sh` (16/0),
  `test-check-capability-activation.sh` (60/0), `test-dev-orchestrator.sh` (188/0),
  `test-design-orchestrator.sh` (24/0), `test-vf-update.sh` (13/0).

## Preuve de la sonde cross-module (demande manager, D-38-H)

`plugin/conductor/skills/vf-update/SKILL.md` (lignes ~19-39) résout `check-gsd-engine.sh` en
cascade `$HOME/.claude/scripts/` → `./.claude/scripts/` → `${CLAUDE_PLUGIN_ROOT}/dev-orchestrator/scripts/`.
Ce lot ne touche QUE `backup_module()`/`rollback_module()` — aucun changement de layout d'install.
Vérifié empiriquement malgré tout (lab jetable, `dev-orchestrator` installé via l'engine MODIFIÉ) :

```
$ install dev-orchestrator (engine modifié) → rc=0, dev-orchestrator v2.20.1 installé
$ ls .claude/scripts/ | grep check-gsd-engine
check-gsd-engine.sh
$ bash ./.claude/scripts/check-gsd-engine.sh --quiet ; echo $?
3
```

`check-gsd-engine.sh` atterrit bien à plat sous `.claude/scripts/` (position 2 de la cascade), la
sonde résout et s'exécute (exit 3 = INDÉTERMINÉ, une branche valide documentée dans le SKILL.md,
pas un échec de résolution). Sonde intacte.

## Next Phase Readiness

Prêt pour 38-04. Point à trancher par le manager avant/à la revue : VERSION/CHANGELOG
`plugin/conductor` restent à `v1.28.1` — à bumper par qui de droit (probablement le lot FIDE, qui
possède déjà ces fichiers en écriture ce tour-ci) une fois les deux lots convergés sur ce fichier
partagé.

---
*Phase: 38-portabilit-multi-runtime-livraison-canal-d-install-migration*
*Completed: 2026-08-28*
