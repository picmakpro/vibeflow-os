---
quick_id: 260928-ccz
status: complete
date: 2026-09-28
---

# Summary — correction ciblée lot 3, Phase 44

Correction ciblée exécutée directement par vf-coder (mandat `vf-dev-manager-g44`), pas par un
cycle planner/executor standard (`gsd-planner`/`gsd-executor` ne figurent pas dans l'allowlist de
vf-coder) — voir la note de méthode du PLAN.md. Ce quick a servi à tracer et vérifier ce travail
(commits atomiques, `gsd-verifier`), pas à le refaire.

## Ce qui a été fait

**Commit `dab3f62`** — `plugin/planning-core/scripts/recalc-planning.sh` :
- Constat 1 (revue) : `lignes_a_journaliser` comparait la valeur BRUTE de l'unité courante au
  jeton déjà assaini relu dans `cloture.log`. La comparaison porte désormais sur
  `_jeton_journal(chemin, "-")` / `(_jeton_journal(verdict, "-"), _jeton_journal(tentative, "-"))`
  des deux côtés.
- Constat 2 (audit) : `detection_gsd()` — nouvelle branche dans le repli code 1 : quand STATE.md
  porte `planning_version` ET qu'un signal de code (`package.json`, etc.) est présent à la racine
  du lab, le verdict est `non-concluante` (refus), reproduisant en Python pur (`_porte_planning_version`,
  `_a_signal_de_code`) la priorité 3 de `detect-gsd-engine.sh` que le détecteur n'a jamais pu
  atteindre (sorti en code 1 avant). `bash` résolu par `shutil.which` plutôt que par le PATH hérité.

**Commit `89270fa`** — `plugin/planning-core/scripts/tests/test-recalc-planning.sh` :
- `R-DEDOUBLONNAGE-ASSAINI` : round-trip réel (2 exécutions de `recalc-planning.sh`, pas un appel
  de fonction isolé) sur la valeur piégée exacte de la revue (`"1  FORGED-RECORD  verdict=close
  tentative=99  date=observation"`) — 1 ligne dans `cloture.log` après chaque run,
  `cloture_ajouts=0` au 2e.
- `MUT-DEDOUBLONNAGE-BRUT` : réintroduit exactement le bug (comparaison repliée sur `(verdict,
  tentative)` brut) — tué par le round-trip ci-dessus.
- `MUT-DEDOUBLONNAGE` : motif mis à jour pour suivre le renommage de la ligne de comparaison
  (sinon `make_recalc_mutant` échouait avec « motif absent »).
- `R-GSD-HOME-SIGNAL` (a)/(b) : (a) environnement normal sur un lab socle planning-core
  (`STATE.md` `planning_version`, sans `gsd_state_version`) + signal de code (`package.json`) →
  code 3 ; (b) même lab, `GSD_HOME` pointant vers un chemin inexistant → code 3 identique (avant
  le fix : code 0, `STATE.md` écrasé). Empreinte de `.planning/` inchangée dans les deux cas.
- `MUT-CODE1-SOCLE-SIGNAL` : neutralise le nouveau repli — tué par R-GSD-HOME-SIGNAL (b).
- 171 → 180 OK, 0 KO.

**Commit `22381c1`** — documentation : `CHANGELOG.md` (paragraphe lot 3 sous l'entrée v2.8.0, pas
de nouvelle version) ; `modele-cycles.md` (table des codes du détecteur scindée sur le cas
code 1 + socle+signal, paragraphe explicatif).

## Correction de la revue précédente

Le `260928-b4c-VERIFICATION.md` (truth #10) avait déclaré VERIFIED le dédoublonnage sans round-trip
réel — un appel de fonction isolé ne peut pas révéler l'écart entre la valeur brute comparée côté
calcul et le jeton assaini relu côté fichier. Cette correction ajoute ce round-trip
(`R-DEDOUBLONNAGE-ASSAINI`) comme garde permanente.

## Preuves

- `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` → 180 OK / 0 KO.
- Reproduction manuelle RED/GREEN, constat 1 (fixture `traceur` + `VERDICT.md` `tentative` piégée,
  deux exécutions réelles) :
  - Sur `ab732a8` (avant fix) : rc1=0, 1 ligne après le run1 ; rc2=0, **2 lignes** après le run2,
    `cloture_ajouts=1` (ligne dupliquée).
  - Sur le fix (ce commit) : rc1=0, 1 ligne ; rc2=0, **1 ligne**, `cloture_ajouts=0`.
- Reproduction manuelle RED/GREEN, constat 2 (lab avec `STATE.md` `planning_version: "2.0"` +
  `package.json`, `.planning/config.json` adhérent) :
  - Sur `ab732a8` (avant fix), `GSD_HOME` pointant vers un chemin inexistant : rc=0, `STATE.md`
    écrasé (contenu généré `genere_par: recalc-planning`).
  - Sur le fix (ce commit) : environnement normal → rc=3 ; `GSD_HOME` inexistant → rc=3 identique,
    empreinte de `.planning/` inchangée dans les deux cas.
- 8 suites sœurs de `plugin/planning-core/scripts/tests/` vertes, non modifiées (`git status
  --short` ne les liste pas après les 3 commits de ce lot).
- Sonde `PY39-SYNTAXE-OK` verte sous `/bin/bash` et `/bin/zsh`.
- `bash scripts/check-machine-paths.sh`, `bash scripts/check-version-sync.sh`,
  `bash plugin/conductor/scripts/check-planning-consumers-registered.sh`,
  `bash scripts/check-gate-touche.sh` : tous verts.
- Aucun bump de version : `v2.8.0` reste non publiée (entrée CHANGELOG complétée, pas de nouvelle
  entrée).
