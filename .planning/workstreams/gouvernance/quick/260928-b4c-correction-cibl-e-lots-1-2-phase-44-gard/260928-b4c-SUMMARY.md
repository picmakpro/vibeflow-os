---
quick_id: 260928-b4c
status: complete
date: 2026-09-28
---

# Summary — correction ciblée lots 1+2, Phase 44

Correction ciblée exécutée directement par vf-coder (mandat `vf-dev-manager-g44`), pas par un
cycle planner/executor standard (`gsd-planner`/`gsd-executor` ne figurent pas dans l'allowlist de
vf-coder) — voir la note de méthode du PLAN.md. Ce quick a servi à tracer et vérifier ce travail
(commits atomiques, `gsd-plan-checker`, `gsd-verifier`), pas à le refaire.

## Ce qui a été fait

**Commit `e4898a0`** — `plugin/planning-core/scripts/recalc-planning.sh` :
- F3 : `_lister_entrees` consomme `os.scandir` entièrement dans son `try`.
- F4 (audit B) : `.recalc-cache.json` ajouté à la liste vérifiée par `appliquer_ecritures` ;
  `os.path.isfile` remplacé par `est_fichier_regulier` (lstat) — un lien symbolique à
  l'emplacement d'INDEX.md/STATE.md/cloture.log/.recalc-cache.json est REFUSÉ, jamais remplacé.
- F5 : `ecrire_si_different` ferme toujours son descripteur temporaire (`fd_non_adopte`).
- F6 : `combinaison-non-prevue` documenté en commentaire comme inatteignable aujourd'hui.
- Lot 2 L1 : `motif-code-2-ou-3` scindé en `motif-code-3-terrain-libre` (écriture autorisée) et
  `motif-code-2-migration` (écriture refusée — régression corrigée de l'audit B).
- Lot 2 L2 : `_jeton_journal` assainit chemin/auteur/verdict/tentative avant écriture dans
  `cloture.log`.

**Commit `aa8420d`** — `plugin/planning-core/scripts/tests/test-recalc-planning.sh` :
- Nouveaux tests + mutants pour F3, F5.
- Un mutant par marqueur non couvert de `detection_gsd()` (6 en lot 1 + fixture dédiée
  `motif-partition-compartiment`, 2 issus du scindage lot 2).
- Régression `R-CODE2-MIGRATION` (rc=3, message P44-D-02a, empreinte identique).
- Test + mutant `L2`/`MUT-JOURNAL-SANITIZE` sur la valeur piégée exacte de l'audit.
- `R56`, `MUT-NOFOLLOW`, `MUT-TYPE-ECRITURE` mis à jour pour le nouveau comportement F4.
- 171 OK / 0 KO.

**Commit `fda472a`** — documentation/hygiène : `modele-cycles.md` (DOC-44-03, F6, tables lot 2),
`module.json` (DOC-44-02), `CHANGELOG.md` (entrée correctifs sous v2.8.0, pas de nouvelle
version), `44-PASSAGE-LABS.md` (Banc F1), `ROADMAP.md` (« à envisager au cadrage » Phase 45),
`BACKLOG.md` (2 entrées : SKILL.md reporté à la Phase 48, faux rouge local de
`test-vibeflow-update.sh` pour Samuel).

## Non traité (décision explicite du mandat)

Le traitement du code 2 de `detect-gsd-engine.sh` avait été laissé hors périmètre du lot 1
(décision en attente) ; le lot 2, reçu en cours de mandat, l'a tranché et je l'ai traité
(« décision du head sous délégation technique de Willy, session principale, 2026-09-28 »).

## Preuves

- `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` → 171 OK / 0 KO.
- 8 suites sœurs de `plugin/planning-core/scripts/tests/` vertes, non modifiées
  (`git diff --stat` vide sur ces 8 fichiers entre `72eb408` et `HEAD`).
- Sonde `PY39-SYNTAXE-OK` verte sous `/bin/bash` et `/bin/zsh`.
- `bash scripts/check-machine-paths.sh`, `bash scripts/check-version-sync.sh`,
  `bash plugin/conductor/scripts/check-planning-consumers-registered.sh` verts.
- `grep -nE 'import yaml|shell=True|eval\(|exec\(|gsd-core|gsd-tools|get-shit-done|phases_trace'
  plugin/planning-core/scripts/recalc-planning.sh` : rien imprimé.
- Régression F4 reproduite manuellement (lien symbolique sur STATE.md et sur
  .recalc-cache.json vers une cible externe) : avant le fix, exit 0 et lien remplacé en silence
  (confirmé sur le code non modifié) ; après le fix, exit 1, cible et lien intacts.
- Régression lot 2 L1 reproduite manuellement (socle v2 + package.json + config.json cycles-v1 +
  GSD_HOME existant vide) : rouge sur le code d'avant fix (exit 0, INDEX.md/STATE.md/
  .recalc-cache.json écrits), vert après fix (exit 3, empreinte de `.planning/` identique).
