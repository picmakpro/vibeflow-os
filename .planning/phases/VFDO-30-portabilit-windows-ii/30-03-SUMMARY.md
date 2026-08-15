---
phase: 30-portabilit-windows-ii
plan: 03
subsystem: veille-release
tags: [wktr-03, d-10, gsd-core]
requires: []
provides: [check-gsd-core-update.sh, veille-quotidienne-gsd-core]
affects: [.claude/settings.json (local, gitignoré)]
tech-stack:
  added: []
  patterns: ["cache tmp+mv atomique", "verrou mkdir avec péremption", "gate d'âge --if-older-than", "sort -V pour semver"]
key-files:
  created:
    - scripts/check-gsd-core-update.sh
    - scripts/tests/test-check-gsd-core-update.sh
    - .planning/phases/VFDO-30-portabilit-windows-ii/30-VEILLE-GSD-CORE.md
  modified: []
key-decisions:
  - "Cache dédié `gsd-core-update.json` (distinct de celui de check-plugin-update.sh) pour ne pas entrer en collision avec la veille du plugin."
  - "Champs de cache : threshold/latest/exceeds/checked_at, lus sans dépendance à jq (sed -E, portable BSD/GNU)."
  - "L'armement local (.claude/settings.json) est écrit hors du périmètre de fichiers strict du mandat, car c'est un artefact machine-local non versionné (le gate check-machine-paths.sh le confirme : `git status --porcelain .claude/` ne rend aucune ligne)."
requirements-completed: [WKTR-03]
duration: "~35 min"
completed: "2026-08-15"
coverage:
  - deliverable: "Sonde outillée scripts/check-gsd-core-update.sh (--refresh/--print/--hook/--status/--if-older-than/--help)"
    verification:
      - kind: "command"
        ref: "bash scripts/check-gsd-core-update.sh --help && bash scripts/check-gsd-core-update.sh --print"
        status: pass
    human_judgment: false
  - deliverable: "Suite de tests avec 3 mutations discriminantes (sort -V, réécriture sous échec, gate d'âge)"
    verification:
      - kind: "tests/path#name"
        ref: "scripts/tests/test-check-gsd-core-update.sh (13 cas)"
        status: pass
    human_judgment: false
  - deliverable: "Armement local + trace versionnée de l'armement"
    verification:
      - kind: "command"
        ref: "bash scripts/check-machine-paths.sh && test -f .planning/phases/VFDO-30-portabilit-windows-ii/30-VEILLE-GSD-CORE.md"
        status: pass
    human_judgment: false
---

# Phase 30 Plan 03: Veille de release @opengsd/gsd-core Summary

Sonde `scripts/check-gsd-core-update.sh` interrogeant `npm view @opengsd/gsd-core version` (jamais
le dist-tag `next`), comparant par `sort -V` contre le seuil `1.10.0`, gatée par un cache quotidien
et un backstop hors-ligne qui ne réécrit jamais le cache sous échec.

**Durée** : ~35 min. **Tâches** : 3/3. **Fichiers touchés** : 3 versionnés + 1 armement local
(`.claude/settings.json`, gitignoré, non compté dans les 3 fichiers du mandat).

## Accomplissements

- `scripts/check-gsd-core-update.sh` : 5 modes (`--refresh`, `--print`, `--hook`, `--status`,
  `--if-older-than <N>d`) + `--help`. Seuil `1.10.0` en constante surchargeable par environnement
  (`VF_GSD_CORE_THRESHOLD`, `VF_GSD_CORE_PACKAGE`, `VF_GSD_CORE_CACHE_DIR` pour l'isolation des
  tests). Verrou `mkdir` atomique avec péremption (300s), écriture cache tmp+mv, `newer()` par
  `sort -V` reprise du patron `check-plugin-update.sh`.
- `scripts/tests/test-check-gsd-core-update.sh` : 13 cas (T1-T9 + contrôle cache réel non touché)
  + 3 mutations. Isolation totale via `mktemp -d` et un shim `npm` déposé sur un PATH monté pour le
  test (patron `test-audit-infra.sh`) — aucun appel réseau réel.
- `.planning/phases/VFDO-30-portabilit-windows-ii/30-VEILLE-GSD-CORE.md` : trace versionnée nommant
  explicitement le caractère non distribué de l'armement (`.claude/` gitignoré, confirmé par
  `git check-ignore -v`), avec la commande exacte de ré-armement (marqueurs `{{ABS_PATH_TO_BASH}}` /
  `{{ABS_PATH_TO_REPO}}`, jamais un chemin réel).
- Armement local dans `.claude/settings.json` (créé, n'existait pas) : entrée `SessionStart` en
  forme exec (`command: "/bin/bash"`, `args: [".../check-gsd-core-update.sh", "--hook"]`),
  dogfooding de la doctrine exec de la phase.

## Bug corrigé en cours de tâche 2 (déviation Rule 1)

**[Rule 1 - Bug] `read_bool_field()` ne matchait jamais sur macOS.** Trouvé en tâche 2 en écrivant
T2/T3/T4 (tous rendaient « cache imparsable » alors que le cache écrit était valide). Cause : le
`sed` BSD de macOS n'interprète pas `\|` comme une alternation en BRE (regex basique) — seul GNU sed
le fait en extension. `sed -n "s/.../\\(true\\|false\\).../p"` ne matchait donc jamais `"exceeds":true`.
Fix : `sed -n -E "s/.../(true|false).../p"` (ERE explicite, portable BSD/GNU). Fichier :
`scripts/check-gsd-core-update.sh`. Vérifié par re-exécution complète de la suite (13/13 OK).
Commit : inclus dans le commit unique de la tâche (pas de commit séparé — corrigé avant tout commit).

## Traces de mutation (QUAL-01, attendu/obtenu)

- **m1 (sort -V → comparaison de chaînes)** : cas T3 (piège semver, seuil 1.9.0 / publié 1.10.0).
  Attendu : signal ROUGE = silence (`--print` vide) là où l'original signale. Obtenu : mutant
  `out=''` (muet, incorrect) vs original `out` non-vide nommant `1.10.0` (correct). PASS.
- **m2 (cache réécrit même sous échec réseau)** : cas T4 (réseau KO après cache valide). Attendu :
  ROUGE = cache modifié malgré l'échec. Obtenu : `cmp -s` entre cache avant/après retourne faux
  (fichiers différents) après la mutation — la comparaison octet-pour-octet capte la réécriture
  indue. PASS.
- **m3 (gate d'âge retiré)** : cas T6 (gate quotidien, deux `--refresh` consécutifs). Attendu :
  ROUGE = le compteur d'invocations du shim `npm` passe à 2 au lieu de 1. Obtenu : compteur = 2
  après mutation (`is_stale` forcé à `true` via `true || {...}`), compteur = 1 sur l'original
  restauré. PASS.

Les trois mutants ont été construits par substitution `awk` ciblée, vérifiés `cmp`-différents de
l'original (jamais `diff`, proxifié sur ce poste), et le script original a été restauré après
chaque mutation (fichiers temporaires sous `mktemp -d`, jamais le script versionné modifié en
place).

## Deviations from Plan

**[Rule 1 - Bug] `read_bool_field()` incompatible BSD sed** — voir section dédiée ci-dessus.

**Total deviations : 1 auto-fixé.** Impact : correctif mineur découvert et réparé avant tout
commit ; aucun résidu, suite 13/13 verte après fix.

## Écart de périmètre assumé (à signaler au manager)

Le mandat listait strictement 3 fichiers versionnés. Deux artefacts supplémentaires ont été
produits, hors de cette liste stricte mais nécessaires à la tâche 3 telle que planifiée :

1. `.claude/settings.json` — armement local, **non versionné** (gitignoré, confirmé
   `git status --porcelain .claude/` = aucune ligne). N'entre dans aucun commit.
2. Ce fichier (`30-03-SUMMARY.md`) — sortie standard du plan (`<output>` du PLAN.md), nommé de
   façon unique à ce plan (aucune collision possible avec un worker voisin). Créé car son absence
   bloque `safe_resume_gate` pour tout plan postérieur du DAG (incident déjà connu sur ce dépôt).

## Delta compteur de suites (pour le plan 30-08, README.md / README.fr.md)

+1 suite de tests : `scripts/tests/test-check-gsd-core-update.sh` (13 cas). Ne pas toucher les
README depuis ce plan — propriété du plan 30-08.

## Next Phase Readiness

Requirement WKTR-03 complété. La sonde tourne sur ce poste (`--status` renvoie « aucun cache —
jamais rafraîchie » tant qu'aucun `--refresh`/`--hook` n'a réussi ; premier `--hook` au prochain
démarrage de session la peuplera). Prête pour la revue (`vf-reviewer`, dispatchée en direct par le
manager) et pour l'intégration au plan de bataille de la Phase 30.
