---
phase: 44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque
plan: 05
subsystem: planning-core
tags: [version, release-discipline, phase-boundary, machine-paths, fresh-lab, read-only-pass]

requires:
  - phase: 44-04
    provides: "moteur recalc-planning.sh complet (hors modèle, garde-fous de chemin, cache incrémental), 9 suites de tests, référence modele-cycles.md"
provides:
  - "plugin/planning-core v2.8.0 : bump mineur sans release (VERSION, module.json, README, CHANGELOG)"
  - "preuves de phase : frontière GSD, suites existantes, socle v2/installeur/CI/SKILL.md/agents intacts, aucun chemin de lab dans le code livré, lab frais final, toutes les suites du dépôt"
  - "44-PASSAGE-LABS.md : mesures du passage en lecture seule sur ~/jarvis-keystone et ~/BusinessFlow-Lab, empreinte sha256 identique avant/après"
affects: ["45", "46", "47", "48", "49", "50"]

actuals:
  tokens: 8527
  tasks: 3
  commits: 3
  plan_head_before: 0faf6cc1f4c7d783b2f00372742a41500a4277e4

tech-stack:
  added: []
  patterns:
    - "Diff complet de la phase mesuré par git merge-base HEAD origin/main, jamais un SHA recopié ni déduit de l'adjacence de git log — rejoué en commandes simples séparées sous la garde d'isolation du worktree"
    - "Passage en lecture seule sur un lab réel : empreinte sha256 de l'arbre complet (os.walk followlinks=False) avant/après + cmp en session, seuls les deux sha256 du fichier d'empreinte (pas des fichiers du lab) survivent dans le rapport versionné — jamais un jeton « identique » écrit à la main"

key-files:
  created:
    - .planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-PASSAGE-LABS.md
  modified:
    - plugin/planning-core/VERSION
    - plugin/planning-core/module.json
    - plugin/planning-core/README.md
    - plugin/planning-core/CHANGELOG.md

key-decisions:
  - "Aucune PR ouverte de fiabilite ne bumpe planning-core au moment de l'exécution (gh pr list --state open, vide) : pas de renumérotation à anticiper (P44-D-18)."
  - "unites (JSON --read-only) n'est pas un champ littéral du rapport de recalc-planning.sh : dérivé comme somme des valeurs de compte_par_etat (phases+plans), le moteur ne l'expose que par état."
  - "Les deux suites rouges hors planning-core (test-check-description-fidelity.sh : PyYAML absent du poste ; test-dev-orchestrator.sh T28-F : table de capabilities dérivée de l'installation locale) sont consignées ci-dessous avec la preuve qu'elles ne lisent aucun fichier du diff de phase, conformément à l'action de la Tâche 2 — tranchées par la CI de la PR, pas par ce plan."

requirements-completed: [MOTR-01, MOTR-02, MOTR-14, MOTR-15, MOTR-17, MOTR-18]

coverage:
  - id: T1
    description: "planning-core reçoit un bump mineur (VERSION, module.json, ligne Version du README, entrée en tête du CHANGELOG) calculé depuis sa valeur à la base de la phase, sans aucun bump racine ni tag"
    requirement: "MOTR-18"
    verification:
      - kind: other
        ref: "sonde du plan : PLANNING-CORE-VERSION-OK base=v2.7.1 attendu=v2.8.0 obtenu=v2.8.0 ; scripts/check-version-sync.sh rc=0 ; diff des fichiers de version racine vide ; git tag --points-at HEAD vide"
        status: pass
    human_judgment: false
  - id: T2
    description: "le diff complet de la phase (merge-base HEAD origin/main) ne touche ni le moteur GSD ni plugin/dev-orchestrator/ ; les suites existantes de planning-core sont vertes et non modifiées ; le socle v2/installeur/CI/SKILL.md/agents/baseline sont intacts ; aucun chemin machine-local des deux labs en forme chemin n'est introduit"
    requirement: "MOTR-01, MOTR-02, MOTR-15"
    verification:
      - kind: other
        ref: "voir § Preuves de phase ci-dessous — toutes les sondes du plan rejouées et vertes"
        status: pass
    human_judgment: false
  - id: T3
    description: "livraison rejouée dans un lab frais (installeur inchangé, HOME temporaire réassigné dans le fichier) et toutes les suites du dépôt tournées"
    requirement: "MOTR-14, MOTR-17"
    verification:
      - kind: integration
        ref: "LAB-FRAIS-FINAL-OK ; SUITES-TOUTES n=91 vertes=89 (2 rouges hors planning-core, documentées, ne lisent aucun fichier du diff de phase)"
        status: pass
    human_judgment: false
  - id: T4
    description: "passage en lecture seule sur deux labs réels, sans écriture, mesuré (temps, indéterminés) et prouvé par comparaison de deux sha256 d'empreinte persistés"
    requirement: "MOTR-17"
    verification:
      - kind: integration
        ref: "PASSAGE-LABS-OK ; deux lignes PASSAGE-LAB, empreinte_avant = empreinte_apres sur les deux labs"
        status: pass
    human_judgment: false

duration: session d'exécution continue, non chronométrée avec précision
completed: 2026-09-28
status: complete
---

# Phase 44 Plan 05: Clôture — version mineure, preuves de phase, passage en lecture seule sur deux labs réels Summary

**`planning-core` passe en v2.8.0 sans aucune release (jalon gouvernance sans release avant
clôture de `fiabilite-v1.0`), toutes les frontières que 44-CONTEXT.md impose sont prouvées sur le
diff complet de la phase (moteur GSD intact, suites existantes intactes et vertes, aucun chemin
machine-local des deux labs dans le code livré), la livraison est rejouée dans un lab frais, et le
moteur a tourné en lecture seule sur `~/jarvis-keystone` et `~/BusinessFlow-Lab` sans y écrire un
octet — prouvé par deux empreintes sha256 identiques avant/après, jamais un jeton écrit à la
main.**

## Performance

- **Duration:** session d'exécution continue, non chronométrée avec précision
- **Completed:** 2026-09-28
- **Tasks:** 3/3
- **Files modified:** 4 (VERSION, module.json, README.md, CHANGELOG.md de `planning-core`) + 1 créé
  (`44-PASSAGE-LABS.md`)
- **Commits:** 3 (mesuré : `git rev-list --count 0faf6cc..HEAD`, avant ce commit de SUMMARY)

## Accomplishments

### Tâche 1 — version mineure, aucune release

- `plugin/planning-core` : `VERSION` v2.7.1 → v2.8.0, `module.json` aligné, ligne `**Version**`
  du README mise à jour, arborescence « Contenu du module » complétée avec `recalc-planning.sh`,
  `references/modele-cycles.md` et `references/templates/cycles/`, compteur de suites corrigé
  (5 → 9, compté sur disque : `ls plugin/planning-core/scripts/tests/test-*.sh | grep -c .`),
  nouvelle section `## Moteur par cycles (recalc-planning.sh)`.
- `CHANGELOG.md` : entrée `## [v2.8.0] — 2026-09-28 (moteur de planning métier — modèle par
  cycles et recalcul d'état dérivé du disque, Phase 44)`, `**Minor**`, décrivant ce qui a été
  livré par 44-01 à 44-04 (recalc-planning.sh et sa voie de livraison, modèle et gabarits, huit
  états dont `indéterminé`, dérogations nominatives, INDEX/STATE/cloture.log, incrémental par
  hash, hors modèle, lecture seule, banc synthétique qui gate en CI) et ce qui n'est PAS livré
  (aucun hook ni gate, fichiers générés non protégés, socle v2 non retiré) — citant « Willy,
  AskUserQuestion session principale, 2026-09-27 ».
- Vérifié : aucune PR ouverte de `fiabilite` ne touche `plugin/planning-core/VERSION`
  (`gh pr list` vide) — pas de renumérotation à prévoir.
- Aucun fichier de version racine touché (`VERSION`, `plugin/.claude-plugin/plugin.json`,
  `.claude-plugin/marketplace.json`, `plugin/.codex-plugin/plugin.json`), aucun tag posé sur HEAD.
- `scripts/check-version-sync.sh` : rc=0, triade `VERSION`↔`module.json` alignée pour les 17
  modules, racine inchangée.

### Tâche 2 — preuves de phase

Aucune écriture de code pour cette tâche : chaque commande de vérification a été rejouée depuis la
racine du dépôt, base dérivée par `git merge-base HEAD origin/main` (424cb23c80b3…), jamais un SHA
recopié. Voir § Preuves de phase ci-dessous pour le détail complet.

### Tâche 3 — passage en lecture seule sur deux labs réels

- `~/jarvis-keystone` et `~/BusinessFlow-Lab` mesurés en mode `--read-only`, aucune commande
  `git` lancée dans l'un ou l'autre, aucun `cd` vers eux (chemins construits depuis `$HOME` par
  un pilote Python).
- Empreinte sha256 de l'arbre complet de chaque lab (`.git` compris) prise avant et après le
  passage, comparée par `cmp` en session (identique dans les deux cas) ; les deux sha256 du
  fichier d'empreinte (pas des fichiers du lab) persistés dans `44-PASSAGE-LABS.md` — c'est leur
  égalité, jamais un jeton écrit à la main, qui fait foi.
- Détail et mesures : § Mesures du banc réel ci-dessous, et `44-PASSAGE-LABS.md`.

## Task Commits

1. **Tâche 1 (version, aucune release)** :
   - `feb0d13` `chore(planning-core v2.8.0): moteur de planning métier, modèle par cycles (Phase 44)`
2. **Tâche 2 (preuves de phase)** : aucun commit de code — son seul produit est ce SUMMARY
   (§ Preuves de phase).
3. **Tâche 3 (passage lecture seule)** :
   - `225cb57` `docs(44): passage en lecture seule sur deux labs réels — temps, indéterminés, empreinte identique (P44-D-06a, P44-D-06b)`

**Plan metadata:** ce commit (`docs(44-05): ...`, contenant ce SUMMARY.md, ajouté par cet agent en
fin d'exécution — STATE.md, ROADMAP.md et REQUIREMENTS.md restent hors de son périmètre, tenus par
l'orchestrateur après la vague, conformément au mandat de cette exécution).

## Files Created/Modified

- `plugin/planning-core/VERSION` — v2.7.1 → v2.8.0
- `plugin/planning-core/module.json` — champ `version` aligné
- `plugin/planning-core/README.md` — ligne Version, arborescence (`recalc-planning.sh`,
  `modele-cycles.md`, `templates/cycles/`, compteur de suites 5→9), section « Moteur par cycles »
- `plugin/planning-core/CHANGELOG.md` — entrée `v2.8.0`
- `.planning/workstreams/gouvernance/phases/VFDO-44-.../44-PASSAGE-LABS.md` — créé (mesures du
  passage en lecture seule)

## Preuves de phase (Tâche 2)

Base de la phase (merge-base) : `424cb23c80b31698db1cd232b188abe29128bd19`.

### P44-D-01a — frontière GSD

```
$ git diff --name-only <base>..HEAD | grep -E '(^|/)gsd-core/|^plugin/dev-orchestrator/'
(rien — rc=1)
$ git diff --name-only <base>..HEAD -- plugin/planning-core/scripts/recalc-planning.sh
plugin/planning-core/scripts/recalc-planning.sh
```
La commande imposée n'imprime aucun chemin ; le témoin de plage non vide imprime le fichier
attendu — la base n'est pas introuvable, le vert de la commande imposée est probant.

### P44-D-01b, P44-D-01e, P44-D-15 — existant intact

```
$ git diff --stat <base>..HEAD -- plugin/planning-core/scripts/tests/ \
    ':!.../test-recalc-planning.sh' ':!.../fixtures/recalc-planning-banc.txt'
(vide)
$ python3 -c '... suites existantes ...'
SUITES-EXISTANTES n=8 vertes=8
$ git diff --name-only <base>..HEAD -- SKILL.md hooks/ guard-planning-updated.sh \
    detect-gsd-engine.sh workstream-policy.sh detect-planning-debt.sh \
    check-planning-state.sh planning-context.sh planning-session-snapshot.sh \
    planning-task-context.sh GUIDE.md PROFILES.md bridge-memory.md compartments.md \
    domain-detection.md example-lab-contenu.md gsd-handoff.md templates/*.template.* \
    plugin/_internal/ .github/ scripts/ plugin/**/SKILL.md plugin/**/agents/** \
    .planning/instruction-budget-baselines.tsv
(vide)
```
8 suites existantes de `planning-core` (hors `test-recalc-planning.sh`), aucune modifiée, toutes
vertes. Aucun fichier du socle v2, hook, installeur, CI, script racine, SKILL.md, agent ou
baseline dans le diff de phase.

### P44-D-06a, P44-D-17 — chemins de lab, boucle zsh + bash

```
$ git diff --unified=0 <base>..HEAD -- plugin scripts .github \
    | grep -E '^\+[^+]' | grep -E '[~/](jarvis-keystone|BusinessFlow-Lab)([^A-Za-z0-9_.-]|$)'
(rien — rc=1)
$ <boucle zsh sur les 4 fichiers livrés>
BOUCLE shell=zsh fichiers=4 fautes=0
$ <boucle bash sur les 4 fichiers livrés>
BOUCLE shell=bash fichiers=4 fautes=0
$ bash scripts/check-machine-paths.sh 2>&1 | tail -1
[check-machine-paths] ✓ 1681 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine
```
Aucun chemin machine-local des deux labs, en forme chemin (`~/` ou `/`), introduit par la phase.

### P44-D-14 — lab frais final

```
$ bash "$W/lab-frais-final.sh"   # HOME réassigné DANS le fichier, invocation nue
LAB-FRAIS-FINAL-OK
```
Installeur inchangé (`plugin/_internal/vibeflow-update.sh`), `HOME=$(mktemp -d)` posé et exporté
dans le fichier lui-même — jamais sur la ligne d'invocation (refusée par la garde d'isolation de
worktree, vérifié sur les deux formes). `recalc-planning.sh` exécutable et les gabarits
`templates/cycles/` présents dans le lab frais ; la suite installée est verte.

### Toutes les suites du dépôt

```
$ python3 -c '... toutes les suites test-*.sh sous plugin/ et scripts/ ...'
ROUGE plugin/conductor/scripts/tests/test-check-description-fidelity.sh
ROUGE plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
SUITES-TOUTES n=91 vertes=89
```

Les deux rouges sont **hors `plugin/planning-core/`** et n'appartiennent pas au périmètre de cette
phase. Preuve qu'aucun des deux ne lit un fichier du diff de phase (35 chemins) :

- `plugin/conductor/scripts/tests/test-check-description-fidelity.sh` : `36 KO / 44` (`8 OK`),
  cause unique répétée : `[check-description-fidelity] INDÉTERMINÉ : module PyYAML introuvable
  pour python3 (passe A)` — dépendance Python absente de ce poste, sans rapport avec `planning-core`
  (module `conductor`, script `check-description-fidelity.sh`). La suite documente elle-même son
  T2 comme « ROUGE DE NON-RÉGRESSION ATTENDU avant Tâche 5 (conversion) ». Aucune correspondance
  textuelle avec l'un des 35 chemins du diff de phase.
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` : `1 KO / 229`
  (`T28-F fraîcheur (ATTEINTE) : la copie versionnée a DÉRIVÉ du registre du moteur installé`) —
  la table de capabilities de `dev-orchestrator` a dérivé de l'installation GSD locale du poste,
  sans rapport avec `planning-core`. Seule correspondance textuelle : `$MOD/README.md` où
  `MOD=plugin/dev-orchestrator` (motif générique du script, pas une référence à un fichier du
  diff de phase — vérifié : `MOD="$(cd "$(dirname "$0")/../.." && pwd)"`).

Ces deux rouges sont pré-existants (modules jamais touchés par la Phase 44) et se tranchent par la
CI de la PR, conformément à l'action de la Tâche 2 — non corrigés ici (hors périmètre).

## Mesures du banc réel (Tâche 3)

| Lab | rc | Durée | Adhésion | Unités dérivées | Indéterminé (unités) | Cycles | Indéterminé (cycles) | Hors modèle | Empreinte avant/après |
|---|---|---|---|---|---|---|---|---|---|
| `~/jarvis-keystone` | 0 | 0,126 s | `2.0` (non adhérent) | 0 | 0 | 10 | 10 | 145 | identiques (sha256 `e0b8c961…`) |
| `~/BusinessFlow-Lab` | 0 | 0,066 s | `2.0` (non adhérent) | 0 | 0 | 0 | 0 | 0 | identiques (sha256 `6cac2146…`) |

Aucune écriture : le `cmp` des deux fichiers d'empreinte (session) rend 0 sur les deux labs, et
les deux sha256 persistés dans `44-PASSAGE-LABS.md` sont strictement égaux, avant et après, sur
chaque lab. Aucune commande `git` lancée dans l'un ou l'autre lab. Détail complet, procédure et
lignes machine `PASSAGE-LAB` : voir `44-PASSAGE-LABS.md`.

Les deux labs n'ayant pas adhéré au nouveau modèle (`adhesion.declaree = "2.0"`), la mesure dit
surtout ce que le moteur fait d'un planning ancien plutôt qu'un banc au modèle par cycles :
`jarvis-keystone` a 10 cycles mais 0 unité dérivée (chaque cycle rend `indéterminé` dès la
racine, `CYCLE.md-absent`, sans descendre dans ses phases) ; `BusinessFlow-Lab` n'a pas de dossier
`cycles/` du tout. Comparaison aux ordres de grandeur de la spec (9,7 à 12,4 s à 3 000 phases)
structurellement non pertinente ici : aucune phase n'a été descendue dans les deux cas.

## Decisions Made

Voir `key-decisions` en frontmatter.

## Deviations from Plan

### Auto-fixed Issues

Aucune. Le plan a été exécuté tel qu'écrit ; les trois tâches sont passées sans nécessiter de
correction Rule 1/2/3.

### Point signalé par le mandat (piège de capture de code de retour, R4)

Le mandat de cette exécution demandait de corriger « au passage » un piège où le code de retour
d'un `git` placé en étage non final d'un pipe serait capturé AVANT le pipe, s'il était rencontré
dans un script/une vérification écrit ou rejoué pour ce plan. Vérification faite : aucune des
commandes de vérification rejouées pour ce plan (Tâches 1 à 3), ni les deux scripts Python écrits
pour la Tâche 3 (`empreinte.py`, `passage.py`), ne capture le code de retour d'un `git` en étage
non final d'un pipe via `$?` — les usages de `git ... | grep ...` de ce plan testent
délibérément le code de retour de `grep` (aucune correspondance = vert), et les autres appels
`git` de ce plan sont soit en tête de pipe suivis de redirection vers un fichier (jamais un pipe),
soit sans pipe du tout. Aucune correction n'était donc nécessaire dans le périmètre de ce plan ;
consigné ici pour traçabilité.

**Total deviations:** 0 auto-fixées. Aucun changement de périmètre.

## Issues Encountered

Aucun blocage. Les deux préconditions de la Tâche 3 (`~/jarvis-keystone/.planning` et
`~/BusinessFlow-Lab/.planning` présents) étaient satisfaites.

Deux suites de test hors `plugin/planning-core/` sont rouges pour des causes pré-existantes et
sans rapport avec cette phase (voir § Preuves de phase, « Toutes les suites du dépôt ») — non
corrigées ici, tranchées par la CI de la PR, comme le prescrit explicitement l'action de la
Tâche 2.

## User Setup Required

None — aucune configuration de service externe requise.

## Next Phase Readiness

- La Phase 44 est complète : modèle de données, recalcul d'état dérivé du disque, hors modèle,
  cache incrémental, version mineure sans release, frontières prouvées sur le diff complet, et
  passage en lecture seule mesuré sur deux labs réels sans écriture.
- STATE.md, ROADMAP.md et REQUIREMENTS.md (marquage des exigences `MOTR-01, MOTR-02, MOTR-14,
  MOTR-15, MOTR-17, MOTR-18`) restent hors du périmètre de cet agent — à mettre à jour par
  l'orchestrateur après la vague, conformément au mandat de cette exécution.
- Aucune release du jalon gouvernance : `planning-core` v2.8.0 n'est ni taggé ni publié ; la
  `VERSION` racine, `plugin/.claude-plugin/plugin.json` et `.claude-plugin/marketplace.json`
  restent inchangés (P44-D-18, garde-fou du jalon jusqu'à la clôture de `fiabilite-v1.0`).
- Aucun hook ni gate câblé (D-15) : le recalcul reste une commande, son déclenchement se décide
  en 45/48. Le socle v2 existant de `planning-core` reste inchangé et actif pour tout lab qui n'a
  pas adhéré.
- Les deux suites rouges hors `planning-core` (`test-check-description-fidelity.sh`,
  `test-dev-orchestrator.sh`) restent à trancher par la CI de la PR — non bloquantes pour la
  clôture de cette phase, hors de son périmètre.

---
*Phase: 44-moteur-modele-de-donnees-et-recalcul-d-etat-derive-du-disque*
*Plan: 05*
*Completed: 2026-09-28*

## Self-Check: PASSED

- `plugin/planning-core/VERSION` = `v2.8.0` (relu sur disque) ; `module.json` `.version` = `v2.8.0`.
- Ligne `**Version** : v2.8.0` présente dans `plugin/planning-core/README.md` ; tête du CHANGELOG
  `## [v2.8.0] — 2026-09-28 (...)`.
- `scripts/check-version-sync.sh` rejoué : rc=0.
- `.planning/workstreams/gouvernance/phases/VFDO-44-.../44-PASSAGE-LABS.md` présent sur disque,
  contient les deux lignes `PASSAGE-LAB` (jarvis-keystone, BusinessFlow-Lab), `empreinte_avant` =
  `empreinte_apres` sur les deux.
- Commits `feb0d13` et `225cb57` retrouvés dans `git log --oneline`.
- `git diff --name-only 424cb23c..HEAD -- VERSION .claude-plugin/marketplace.json
  plugin/.claude-plugin/plugin.json plugin/.codex-plugin/plugin.json` : vide. `git tag
  --points-at HEAD` : vide.
- `bash scripts/check-machine-paths.sh` rejoué : vert (1682 fichiers suivis après ajout de
  `44-PASSAGE-LABS.md`).
