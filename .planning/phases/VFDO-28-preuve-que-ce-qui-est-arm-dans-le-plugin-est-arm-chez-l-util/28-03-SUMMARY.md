---
phase: VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util
plan: 03
subsystem: ci
tags: [ci, github-actions, as-installed-testing, check-capability-activation, versioning]

requires:
  - phase: 28-01
    provides: "Règle 4 + 4bis de check-capability-activation.sh, 4 planchers anti-vert-à-vide"
  - phase: 28-02
    provides: "Liste close étendue (vf-mcp-consumer/vf-mcp-tools), opposabilité des porteurs, 5 bornes"
provides:
  - "Job CI lab-frais-arme : le gate check-capability-activation.sh tourne installé (.claude/scripts/), fermeture dev-orchestrator (9 modules), sur un univers armé (>=2 artefacts)"
  - "dev-orchestrator v2.15.0, conductor v1.23.0 — journaux de la Phase 28 complète"
affects: [ci.yml, dev-orchestrator, conductor]

actuals:
  tokens: 4313
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "as-installed testing : un job CI installe sa propre fermeture dans son propre mktemp -d, distinct du lab voisin, et invoque le gate au chemin INSTALLÉ (.claude/scripts/), jamais depuis l'arbre source"

key-files:
  created: []
  modified:
    - ".github/workflows/ci.yml"
    - "plugin/dev-orchestrator/VERSION"
    - "plugin/dev-orchestrator/module.json"
    - "plugin/dev-orchestrator/CHANGELOG.md"
    - "plugin/dev-orchestrator/README.md"
    - "plugin/conductor/VERSION"
    - "plugin/conductor/module.json"
    - "plugin/conductor/CHANGELOG.md"
    - "plugin/conductor/README.md"
    - ".planning/phases/VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util/28-01-VERIFICATION.md"
    - ".planning/phases/VFDO-29-distiller-les-gains-icm-g1-g5-investigation-dag-sh-scope-d-a/29-RESEARCH.md"

key-decisions:
  - "Checkpoint D-04 tranché par l'humain HORS session (relayé par le mandat) : `second-job-9-modules`. Corps de la tâche 1 appliqué TEL QU'ÉCRIT (cas nominal), sans le bloc <branching> substitué."
  - "Collision de version tranchée par l'humain : le bump réel part des valeurs déjà posées par un commit étranger (Phase 29, 6897d59) — dev-orchestrator v2.14.0→v2.15.0, conductor v1.22.0→v1.23.0 — au lieu des valeurs obsolètes du plan (v2.13.1→v2.14.0, v1.21.1→v1.22.0). Les acceptance criteria de la tâche 2 ont été re-pointés sur v2.15.0/v1.23.0 pour rester discriminants."
  - "Config minimale du lab armé mesurée en local avant écriture du YAML : une seule clé (`intel.enabled: true`) suffit à faire passer le gate sur la fermeture dev-orchestrator + config.json vide (règle 2 rougissait sinon sur intel.enabled, hors périmètre de la phase) — bien sous le plafond de trois."

requirements-completed: [ARMD-06, ARMD-08]

coverage:
  - id: D1
    description: "Job CI `lab-frais-arme` : installe la fermeture dev-orchestrator (9 modules) dans son propre lab, pose une config minimale, invoque le gate INSTALLÉ sans surcharge, échoue sur exit 2 comme sur exit 1, refuse un univers d'armement < 2"
    requirement: "ARMD-06"
    verification:
      - kind: other
        ref: "reproduction locale pas-à-pas des 5 étapes du job (install closure, config, gate rc=0, armed_count=2) — voir section « Vérification de bout en bout »"
        status: pass
    human_judgment: true
    rationale: "Le job n'a pas été exécuté en conditions réelles GitHub Actions (aucun push effectué — hors périmètre de ce mandat d'exécution, ni ship ni PR ne sont autorisés). La reproduction locale, étape par étape, avec les mêmes commandes que le YAML, est probante mais reste une simulation ; le run CI réel doit être lu par le manager/l'humain avant de considérer ce critère définitivement clos."
  - id: D2
    description: "Triades de version cohérentes (VERSION/module.json/CHANGELOG/README) pour dev-orchestrator (v2.15.0) et conductor (v1.23.0), VERSION racine intacte"
    requirement: "ARMD-08"
    verification:
      - kind: other
        ref: "bash scripts/check-version-sync.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Déviation déclarée : 2 chemins absolus de machine préexistants (hérités de main) corrigés minimalement, gate machine-paths vert"
    verification:
      - kind: other
        ref: "bash scripts/check-machine-paths.sh"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-08-15
status: complete
---

# Phase 28 Plan 03: Job CI as-installed testing + clôture des triades de module Summary

**Le gate `check-capability-activation.sh` tourne désormais là où l'install le pose (job CI
`lab-frais-arme`, fermeture `dev-orchestrator` 9 modules, univers armé ≥2), et les deux modules
touchés par la Phase 28 portent leur triade v2.15.0/v1.23.0 avec journal.**

## Performance

- **Duration:** ~45 min
- **Tasks:** 2 (tâche 1 : job CI ; tâche 2 : clôture des triades) + 1 déviation déclarée (machine-paths)
- **Files modified:** 11

## Décision de checkpoint consignée (D-04)

Réponse humaine, relayée par le mandat (hors session interactive, checkpoint déjà répondu avant
dispatch) : **`second-job-9-modules`**. C'est le cas nominal du bloc `<branching>` de la tâche 1 —
le corps de la tâche a été appliqué **tel qu'écrit**, sans aucune substitution. Portée retenue :
second job CI `lab-frais-arme`, fermeture installée `dev-orchestrator` (9 modules), lab doté d'un
`.planning/config.json` propre, le job `lab-frais` et son Gate C **intacts** (confirmé par diff :
aucune ligne modifiée ni supprimée dans la plage 620-653 de `ci.yml`, seules des additions après
sa fin).

## Accomplishments
- **Job CI `lab-frais-arme`** — 5 étapes : assertion d'outillage (jq/python3), install de la
  fermeture `dev-orchestrator` avec échec visible si `dev-orchestrator` disparaît de la fermeture
  résolue, config minimale mesurée (1 clé), invocation du gate installé sans surcharge
  `VF_CAPACT_*` (exit 2 traité comme exit 1), plancher `>=2` artefacts armés (compté en `awk`,
  jamais en `grep` pipé).
- **`dev-orchestrator` v2.15.0** et **`conductor` v1.23.0** — triades cohérentes et journaux
  décrivant le travail réel de la Phase 28 (règle 4/4bis, jointure `vf-requires`/`# vf-provides`,
  fermeture `ARM_LINE` multi-clés, 4 planchers, 5 bornes, 5 déclarations `vf-requires:
  mcp-servers`, admission de `vf-requires` dans `KNOWN`).
- **Déviation déclarée** : 2 chemins absolus de machine préexistants (hérités de `main`, non
  imputables à ce plan) corrigés minimalement — `scripts/check-machine-paths.sh` repasse vert.

## Task Commits

Chaque tâche a été committée atomiquement, sur la branche `feat/phase-28-03-as-installed` (vérifiée
avant chaque commit) :

1. **Tâche 1 : job CI lab-frais-arme** - `4787c3b` (feat)
2. **Tâche 2 : clôture des triades dev-orchestrator/conductor** - `a8fd33f` (docs)
3. **Déviation déclarée : chemins absolus de machine** - `ab73039` (fix)

**Plan metadata:** committé avec ce SUMMARY (docs).

## Files Created/Modified
- `.github/workflows/ci.yml` - Job `lab-frais-arme` (as-installed testing), 97 lignes ajoutées, aucune ligne de `lab-frais` touchée
- `plugin/dev-orchestrator/{VERSION,module.json,CHANGELOG.md,README.md}` - v2.14.0 → v2.15.0
- `plugin/conductor/{VERSION,module.json,CHANGELOG.md,README.md}` - v1.22.0 → v1.23.0
- `.planning/phases/VFDO-28-.../28-01-VERIFICATION.md`, `.planning/phases/VFDO-29-.../29-RESEARCH.md` - correction minimale des 2 violations machine-paths préexistantes (forme documentée par le gate, aucun changement de nombre de lignes)

## Decisions Made

- **Checkpoint D-04 = `second-job-9-modules`** (décidé par l'humain, hors session, relayé par le
  mandat) — cas nominal, aucune substitution.
- **Bump de version reparti de la valeur déjà posée par la Phase 29** (v2.14.0/v1.22.0, commit
  étranger 6897d59) plutôt que des valeurs obsolètes du plan (v2.13.1/v1.21.1) — décision humaine
  du mandat, acceptance criteria de la tâche 2 re-pointés sur v2.15.0/v1.23.0 pour rester
  discriminants (les valeurs v2.14.0/v1.22.0 du plan existaient déjà, donc non discriminantes).
- **Config du lab armé : une seule clé** (`intel.enabled: true`), mesurée localement avant
  d'écrire le YAML — bien sous le plafond de trois fixé par le plan.
- **Ancres de lecture périmées du plan** (décalage introduit par 28-02, ~65 lignes) corrigées à
  l'exécution contre les positions réelles mesurées (cascade de racine `:206-214`, cascade
  `REF_DIR` `:240-249`, règle memory/disallowedTools de `check-agents.sh` `:621-623`) — sans
  impact sur le contenu produit, conformément au mandat.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug/manque] `scripts/check-version-sync.sh` exige aussi la synchronisation de l'en-tête `Version` des README de module**
- **Found during:** Tâche 2 (clôture des triades)
- **Issue:** Les `files_modified` du plan ne listaient que `VERSION`, `module.json`, `CHANGELOG.md` par module. Or `check-version-sync.sh` (la commande `<verify>` prescrite par le plan) échouait après le bump : `plugin/conductor/README.md` et `plugin/dev-orchestrator/README.md` portent chacun un en-tête `**Version** : vX.Y.Z` que le gate compare aussi à la `VERSION` canonique du module.
- **Fix:** Mise à jour de l'en-tête `Version` des deux README de module, sans autre reformulation.
- **Files modified:** `plugin/conductor/README.md`, `plugin/dev-orchestrator/README.md`
- **Verification:** `bash scripts/check-version-sync.sh` → 0 (avant : ✗ sur les deux en-têtes ; après : `✓ en-tête Version des README de modules : 17 déclarés, tous alignés`)
- **Committed in:** `a8fd33f` (Tâche 2)

**2. [Rule 1 - Bug préexistant, hors périmètre du plan] 2 chemins absolus de machine dans `.planning/` — corrigés en commit séparé, étiqueté déviation déclarée**
- **Found during:** Barre de vert du mandat (`bash scripts/check-machine-paths.sh`)
- **Issue:** Le gate sortait 1 sur exactement deux violations, toutes deux héritées de `main` et non introduites par ce plan : une ligne de `28-01-VERIFICATION.md` citant verbatim un chemin `/Users/<compte>` documentant une violation ailleurs (déjà corrigée depuis dans le fichier cité, donc devenue elle-même la seule violation restante) ; une ligne de `29-RESEARCH.md` pointant le `CLAUDE.md` racine du dépôt par chemin absolu au lieu d'un chemin relatif.
- **Fix:** Formes documentées par le gate lui-même — forme 3 (`/Users/<user>/…`, le chevron n'étant pas un identifiant) pour la citation documentaire ; forme 1 (chemin relatif au dépôt, `CLAUDE.md`) pour le chemin qui pointait réellement dans le dépôt. Aucune reformulation, aucun changement du nombre de lignes des deux fichiers (vérifié par `git diff --stat` : 1 insertion + 1 suppression par fichier).
- **Files modified:** `.planning/phases/VFDO-28-.../28-01-VERIFICATION.md`, `.planning/phases/VFDO-29-.../29-RESEARCH.md`
- **Verification:** `bash scripts/check-machine-paths.sh` → 0 (avant : ✗ 2 violations ; après : `✓ 946 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine`)
- **Committed in:** `ab73039` (commit séparé, étiqueté déviation déclarée dans le message)

---

**Total deviations:** 2 auto-fixées (1 manque de couverture du critère de vérification prescrit, 1 correctif préexistant hors périmètre mais requis par la barre de vert du mandat).
**Impact on plan:** Aucune dérive de scope — les deux corrections sont strictement nécessaires pour que les critères de vérification déjà prescrits (par le plan et par le mandat) passent au vert. Aucun contenu du plan n'a été affaibli ou contourné.

## Issues Encountered

Aucune bloquante. Une limite de preuve à signaler explicitement : la branche
`feat/phase-28-03-as-installed` n'a **pas** été poussée dans le cadre de ce mandat d'exécution (ni
push, ni PR, ni release ne sont autorisés — la release racine reste un geste humain, cf.
`CLAUDE.md`). Le job `lab-frais-arme` a donc été validé par **reproduction locale pas-à-pas des 5
étapes exactes du YAML** (install de la fermeture `dev-orchestrator`, config minimale, invocation
du gate installé → rc=0, comptage des artefacts armés → 2), mais **n'a jamais tourné pour de vrai
sur `ubuntu-latest`**. C'est la même limite de preuve que le plan documente déjà pour `lab-frais`
lui-même (`ci.yml:527-530`, « CE JOB N'AURA JAMAIS TOURNÉ POUR DE VRAI » tant que la branche n'est
pas poussée). Le manager doit lire le run CI réel après push pour clore définitivement le
critère de vérification de bout en bout du plan.

Note technique locale (sans impact sur le YAML produit) : la boucle `for m in $closure` de l'étape
d'install échoue à se découper par mot dans CET environnement Bash-tool spécifique (déjà documenté
en mémoire agent — le shell interactif ne fait pas de word-splitting sur variable non quotée). Le
job `lab-frais` existant, déjà vert en CI de production depuis la Phase 11 avec exactement le même
patron, prouve que ce n'est pas un problème de bash réel. La reproduction locale a donc été
effectuée avec un `while IFS= read -r` équivalent (portable dans les deux mondes) pour valider le
reste du pipeline (install, config, gate, plancher d'armement) sans dépendre de cette
particularité locale.

## User Setup Required

None - aucune configuration de service externe requise.

## Next Phase Readiness

- Le job CI `lab-frais-arme` et les deux triades de module sont prêts à être poussés et revus.
- **Reste ouvert, hors périmètre de ce mandat d'exécution** : pousser la branche
  `feat/phase-28-03-as-installed` et lire le run CI réel (les 4 jobs — `tests`, `gates`,
  `lab-frais`, `lab-frais-arme` — doivent être verts) ; ouvrir la PR ; la release racine
  (`VERSION` → au-delà de v2.51.0) reste un geste humain gaté, hors périmètre de la Phase 28.
- La Phase 28 (28-01, 28-02, 28-03) est désormais complète côté exécution.

---
*Phase: VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util*
*Plan: 03*
*Completed: 2026-08-15*
