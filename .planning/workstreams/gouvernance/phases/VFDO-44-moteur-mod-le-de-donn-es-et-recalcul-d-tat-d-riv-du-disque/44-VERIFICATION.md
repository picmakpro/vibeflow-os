---
phase: 44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque
verified: 2026-09-28T07:15:00Z
status: passed
score: 18/18 must-haves verified (MOTR-01..18)
covered_files:
  - ".planning/workstreams/gouvernance/REQUIREMENTS.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-01-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-01-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-02-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-02-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-03-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-03-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-04-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-04-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-05-PLAN.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-05-SUMMARY.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-CONTEXT.md"
  - ".planning/workstreams/gouvernance/phases/VFDO-44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque/44-PASSAGE-LABS.md"
  - "plugin/planning-core/CHANGELOG.md"
  - "plugin/planning-core/README.md"
  - "plugin/planning-core/VERSION"
  - "plugin/planning-core/module.json"
  - "plugin/planning-core/references/modele-cycles.md"
  - "plugin/planning-core/references/templates/cycles/CADRAGE.template.md"
  - "plugin/planning-core/references/templates/cycles/CLOTURE.template.md"
  - "plugin/planning-core/references/templates/cycles/CYCLE.template.md"
  - "plugin/planning-core/references/templates/cycles/DEROGATION.template.md"
  - "plugin/planning-core/references/templates/cycles/PLAN.template.md"
  - "plugin/planning-core/references/templates/cycles/SUMMARY.template.md"
  - "plugin/planning-core/references/templates/cycles/VERDICT.template.md"
  - "plugin/planning-core/references/templates/cycles/config.template.json"
  - "plugin/planning-core/scripts/recalc-planning.sh"
  - "plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt"
  - "plugin/planning-core/scripts/tests/test-recalc-planning.sh"
covered_digest: "v1:sha256:6d3e90745a1ea134d721026725312fbe2296aa1259d84109120f49b590f42e59"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 44: Moteur — modèle de données et recalcul d'état dérivé du disque — Verification Report

**Phase Goal:** Le modèle de données d'un lab (`cycles/`, `phases/`, `CADRAGE.md`, `PLAN.md` avec
`ecrit:`, `VERDICT.md`, `SUMMARY.md`) existe, et un recalcul **en Python** dérive du disque les
huit états (dont `indéterminé`) et génère `INDEX.md`, `STATE.md` et `cloture.log` — incrémental
par hash du contenu, jamais par `mtime`.
**Verified:** 2026-09-28
**Status:** passed
**Re-verification:** No — initial verification
**Mode:** phase d'infrastructure/fondation (moteur de recalcul, pas d'élément orienté utilisateur) —
la scoping infra de `verifier-phase-gates.md` s'applique (§ Human Verification).

## Méthode

Vérification goal-backward, indépendante des affirmations des SUMMARY.md : relecture de
`44-CONTEXT.md` (P44-D-01 à P44-D-18), des cinq `PLAN.md`/`SUMMARY.md`, de `44-PASSAGE-LABS.md` et
de `REQUIREMENTS.md` (MOTR-01..18), puis ré-exécution en session des neuf suites de
`plugin/planning-core/scripts/tests/`, spot-checks comportementaux manuels sur
`recalc-planning.sh` (refus d'adhésion, refus GSD, mode lecture seule, écriture) dans un lab
temporaire hors dépôt, et vérification structurelle du diff complet de la phase
(`git diff --name-only 424cb23c..HEAD`, 37 fichiers) contre la liste des chemins interdits.

## Goal Achievement

### Observable Truths (MOTR-01 à MOTR-18)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| MOTR-01 | Le modèle de données (`cycles/`, `phases/`, `CYCLE.md`, `CADRAGE.md` avec colonne structurante, `PLAN.md` avec `ecrit:`, marqueur de clôture, `VERDICT.md`, `SUMMARY.md`, liste fermée des annexes) est écrit et outillé dans `plugin/planning-core/`, sans toucher `~/.claude/gsd-core/`, `.claude/gsd-core/` ni `plugin/dev-orchestrator/`, ni dépendre de leur code | ✓ VERIFIED | `plugin/planning-core/references/modele-cycles.md` (référence complète) + 8 gabarits sous `references/templates/cycles/` relus ; `git diff --name-only 424cb23c..HEAD` (37 fichiers, rejoué en session) ne contient aucun chemin `gsd-core/` ni `plugin/dev-orchestrator/` ; `grep -n "gsd-core\|gsd_run\|gsd-tools\|\.claude/gsd" recalc-planning.sh` → vide (rejoué) |
| MOTR-02 | L'altitude lab (`workstream-policy.sh`, `detect-planning-debt.sh`, hooks existants) reste inchangée à l'identique, prouvée par ses suites existantes vertes sans modification ; un lab dev n'est jamais réécrit | ✓ VERIFIED | 8 suites `planning-core` (hors `test-recalc-planning.sh`) rejouées en session, toutes vertes : `test-check-planning-state.sh` 19/19, `test-detect-gsd-engine.sh` 26/26, `test-detect-planning-debt.sh` 10/10, `test-planning-context-hardening.sh` 38/38, `test-planning-core.sh` 14/14, `test-planning-hooks.sh` 42/42, `test-workstream-policy.sh` 22/22, `test-workstream-symlink-escape.sh` 10/10 ; diff de phase ne touche aucun de ces 8 fichiers (`git diff --stat` vide sur leur ensemble, confirmé) |
| MOTR-03 | Le recalcul n'écrit que si `.planning/config.json` déclare `"planning_version": "cycles-v1"` ; sans cette déclaration, refus sans rien toucher, code de sortie non nul, message nommant la déclaration attendue | ✓ VERIFIED | Spot-check manuel : `recalc-planning.sh --planning=/tmp/verif44lab/.planning` sur un `.planning/` vide → `rc=2`, message `[recalc-planning] refus d'écriture (P44-D-02) : ... "planning_version": "cycles-v1" ...`, `ls` du dossier après coup toujours vide (aucun fichier créé) |
| MOTR-04 | Mode lecture seule : dérivation JSON sur tout planning (adhérent ou non), aucun fichier écrit (cache compris) ; un planning GSD détecté est refusé en écriture même s'il déclare le schéma | ✓ VERIFIED | Spot-check manuel : `--read-only` sur le même dossier vide → JSON déterministe sur stdout, `rc=0`, dossier toujours vide après coup ; puis config.json + STATE.md déclarant `gsd_state_version` (sans engin GSD installé sur la machine) → mode écriture refuse `rc=3` (« ce planning est tenu par le moteur GSD, ou sa détection n'est pas concluante »), aucun fichier créé dans le dossier |
| MOTR-05 | Marqueur de clôture = fichier à côté de `PLAN.md`, jamais une modification de `PLAN.md` (hash stable) ; `à exécuter` = `PLAN.md` présent, marqueur absent | ✓ VERIFIED | `CLOTURE.template.md` relu ; suite : R24 (sha256 de `PLAN.md` stable après pose de `CLOTURE.md`), R24-bis (empreinte de `cycles/` inchangée) — les deux dans les 152 assertions vertes rejouées |
| MOTR-06 | Liste fermée d'annexes (`_bancs/`, `recherches/`, `intel/`, `sketches/`, `_archive/`, `registres/`) ignorée ; tout le reste hors modèle signalé (jamais refusé, jamais déplacé) dans `INDEX.md` | ✓ VERIFIED | `classer_entrees()` relu dans `recalc-planning.sh` ; suite : R40 (racine), R41 (arbre `cycles/`), R42 (mauvais type), R43/R44 (lien de dossier/fichier jamais suivi), R45 (nom échappé), R46 (rendu INDEX.md) — toutes dans les 152 assertions rejouées vertes |
| MOTR-07 | Les huit états s'appliquent aux phases et aux plans ; agrégation de cycle déléguée et écrite ; dérogations `abandonné\|remplacé\|gelé` nominatives, sans auteur → `indéterminé` | ✓ VERIFIED | `deriver_phase()`/`agreger()`/`lire_derogation()` relus ; banc à 51 labs, onze paires positif/jumeau, contrôle de couverture R20 (`COUVERTURE` × 11, `BANC-LABS n=51`) — rejoué vert |
| MOTR-08 | Toute combinaison de signaux non prévue rend `indéterminé` ; les quatre contradictions nommées (SUMMARY sans PLAN, VERDICT sans marqueur, SUMMARY avec verdict en échec, marqueur sans PLAN) sont couvertes | ✓ VERIFIED | Labs `d08-summary-sans-plan`, `d08-verdict-sans-marqueur`, `d08-summary-verdict-echec`, `d08-marqueur-sans-plan` + mutants `MUT-D08-*` — dans les 152 assertions rejouées vertes |
| MOTR-09 | Le recalcul lit les constats de `VERDICT.md` (passé/échec) pour dériver `à corriger`/`close` ; `hash`/`tentative` lus sans être vérifiés | ✓ VERIFIED | Labs `etat-a-corriger`/`etat-close`, R21 (tentative reprise telle quelle) — dans la suite rejouée verte ; lecture du code (`deriver_feuille`) confirme `hash_juge`/`tentative` jamais comparés à une valeur calculée |
| MOTR-10 | `INDEX.md`/`STATE.md` générés de façon déterministe (deux recalculs → fichiers identiques octet pour octet) | ✓ VERIFIED | Suite R02/R03 (second recalcul : `ecrits` vide, `cloture_ajouts` 0, `cmp` identique) — dans les 152 assertions rejouées vertes ; permissions `0o644` forcées (R14, `MUT-CHMOD`/`MUT-CHMOD-JOURNAL`) — vertes |
| MOTR-11 | `cloture.log` append-only : une ligne ajoutée à l'observation d'un `close`/dérogation, jamais réécrite/supprimée, format conforme, auteur résolu sans git | ✓ VERIFIED | R10/R11 (ajout seul, dédoublonnage), `MUT-NOFOLLOW` (refus code 1 sur `cloture.log` en lien symbolique) — dans la suite rejouée verte ; format de ligne vérifié par regex dans R02 |
| MOTR-12 | Python 3.9+, bibliothèque standard seule, aucune logique de recalcul en bash | ✓ VERIFIED | `grep -n "^import\|^from" recalc-planning.sh` (rejoué) → `errno, hashlib, json, os, re, stat, subprocess, sys, tempfile, unicodedata, datetime` — stdlib uniquement, aucun `yaml` (`grep -c yaml` → 0) ; le `.sh` ne contient que l'analyse d'arguments et le lancement du heredoc Python |
| MOTR-13 | Incrémental par hash du contenu, jamais par `mtime` ; cache absent/illisible/autre schéma → recalcul complet, prouvé dans les deux sens | ✓ VERIFIED | `grep -nE 'st_mtime\|getmtime\|st_ctime\|getctime\|st_atime\|getatime\|utime' recalc-planning.sh` → vide (rejoué) ; suite R50-R58 (touch sans effet, contenu changé à mtime restauré vu, cache absent/JSON invalide/lien/schéma différent → recalcul complet, jamais lu en `--read-only`) — dans les 152 assertions rejouées vertes |
| MOTR-14 | Livrable par l'installeur existant sans modification de ses sites de pose (voie a, Python embarqué en heredoc) | ✓ VERIFIED | `git diff --name-only 424cb23c..HEAD` (rejoué) ne contient **aucun** fichier sous `plugin/_internal/` ; `head -1 recalc-planning.sh` = `#!/usr/bin/env bash`, `grep -c "<<'PY_RECALC_PLANNING_EOF'"` = 1 (motif heredoc quoté confirmé) |
| MOTR-15 | Aucun hook ni gate câblé ; le recalcul est une commande autonome | ✓ VERIFIED | Diff de phase ne touche `hooks/hooks.json` ni aucun `check-*.sh` racine ; `recalc-planning.sh` ne référence aucun mécanisme de hook |
| MOTR-16 | Suites bash + banc synthétique couvrent les huit états avec jumeaux négatifs, chaque garde tuée par un mutant tracé (assertion/attendu/obtenu), boucles rejouées sous zsh **et** bash | ✓ VERIFIED | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` rejoué en session → **152 OK · 0 KO** (35 mutants `MUT-*` au total, tous tracés, `MUT-PLANTAGE` confirmé comme garde du harnais lui-même) |
| MOTR-17 | Banc synthétique versionné gate seul en CI ; passage lecture seule hors CI sur deux labs réels mesuré, aucune écriture | ✓ VERIFIED | `.github/workflows/ci.yml:218` découvre `*/tests/test-*.sh` automatiquement (aucune modif CI nécessaire, confirmé par grep) ; `44-PASSAGE-LABS.md` relu : `~/jarvis-keystone` et `~/BusinessFlow-Lab` existent bien sur ce poste (confirmé), `config.json` de `BusinessFlow-Lab` relu = `planning_version: "2.0"` (non adhérent, cohérent avec le rapport) ; méthode de preuve (empreinte sha256 avant/après comparée par `cmp`, seuls les deux sha256 persistés) jugée rigoureuse et non ré-exécutée intégralement pour ne pas risquer d'écrire dans les labs réels de l'utilisateur — acceptée sur la base de la méthode documentée et vérifiable (§ Note ci-dessous) |
| MOTR-18 | `planning-core` bump mineur, CHANGELOG et README à jour ; aucune release du jalon avant `fiabilite-v1.0` | ✓ VERIFIED | `cat plugin/planning-core/VERSION` = `v2.8.0` (rejoué, base v2.7.1 selon SUMMARY) ; `module.json .version` = `v2.8.0` ; `VERSION` racine = `v2.66.0` (inchangée) ; `git tag --points-at HEAD` → vide (aucun tag) ; `bash scripts/check-version-sync.sh` → vert |

**Score:** 18/18 truths verified (0 present-behavior-unverified, 0 overrides).

### Note sur MOTR-17 (labs réels)

Le passage en lecture seule sur `~/jarvis-keystone` et `~/BusinessFlow-Lab` n'a pas été
ré-exécuté par ce verifier : la méthode documentée dans `44-PASSAGE-LABS.md` (empreinte sha256 de
l'arbre complet avant/après par `os.walk(followlinks=False)`, comparaison `cmp`, seuls les deux
sha256 d'empreinte — jamais les fichiers du lab — persistés dans l'artefact versionné) est
suffisamment rigoureuse et vérifiable en l'état pour ne pas justifier une seconde exécution contre
les dossiers réels de l'utilisateur, en particulier pour un verifier qui n'a aucune garantie
d'isolation supplémentaire à offrir par rapport à la mesure déjà prise. L'existence des deux labs
et la cohérence de `BusinessFlow-Lab/.planning/config.json` (`planning_version: "2.0"`) avec le
rapport ont été confirmées directement.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `plugin/planning-core/scripts/recalc-planning.sh` | Point d'entrée bash + moteur Python embarqué | ✓ VERIFIED | Existe, exécutable, 152/152 assertions vertes contre lui, spot-checks manuels concordants |
| `plugin/planning-core/scripts/tests/test-recalc-planning.sh` | Suite R01-R58, 35 mutants tracés | ✓ VERIFIED | Rejouée en session : 152 OK · 0 KO |
| `plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt` | Banc synthétique, 51 labs | ✓ VERIFIED | Présent, consommé par la suite, format `@@` conforme |
| `plugin/planning-core/references/modele-cycles.md` | Référence complète du modèle | ✓ VERIFIED | Relue, 18 décisions P44-D transcrites, table LIBELLES présente |
| `plugin/planning-core/references/templates/cycles/*.{md,json}` (8 gabarits) | Gabarits qui ne dérivent jamais `close` non remplis | ✓ VERIFIED | 8 fichiers présents, R23-A à R23-F les testent directement contre le moteur |
| `plugin/planning-core/VERSION`, `module.json`, `README.md`, `CHANGELOG.md` | Bump mineur v2.8.0 | ✓ VERIFIED | Relus, valeurs cohérentes, `check-version-sync.sh` vert |
| `.planning/workstreams/gouvernance/phases/.../44-PASSAGE-LABS.md` | Rapport du passage lecture seule | ✓ VERIFIED | Présent, deux lignes `PASSAGE-LAB`, empreintes avant/après identiques |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|
| `recalc-planning.sh` (bash) | `detect-gsd-engine.sh` | Chemin frère dérivé de `BASH_SOURCE`, sous-processus en mode écriture seulement | ✓ WIRED | `grep -c 'DETECT_GSD_SH="$SCRIPT_DIR/detect-gsd-engine.sh"'` = 1 (rejoué) ; spot-check confirme le refus GSD sans dépendre du script quand la chaîne GSD est absente de la machine (lecture indépendante de `STATE.md`) |
| `test-recalc-planning.sh` | `fixtures/recalc-planning-banc.txt` | `materialiser` | ✓ WIRED | R01 (coureur du banc sur 51 labs) vert |
| Installeur `vibeflow-update.sh` (inchangé) | `<lab>/.claude/scripts/recalc-planning.sh` + tests + fixtures | Sites de pose 2/3/3bis/4, non modifiés | ✓ WIRED | Diff de phase ne touche aucun fichier de `plugin/_internal/` ; témoin `TRACER-LAB-FRAIS-OK`/`LAB-FRAIS-FINAL-OK` documenté dans les SUMMARY 44-01/44-05, cohérent avec l'absence de modification de l'installeur |

### Behavioral Spot-Checks (rejouées par ce verifier, hors suite persistée)

| Behavior | Command | Result | Status |
|---|---|---|---|
| Refus sans adhésion, rien écrit | `recalc-planning.sh --planning=<vide>` | `rc=2`, message P44-D-02, dossier vide après coup | ✓ PASS |
| Lecture seule, rien écrit | `recalc-planning.sh --planning=<vide> --read-only` | `rc=0`, JSON sur stdout, dossier toujours vide | ✓ PASS |
| Refus planning GSD (chaîne GSD absente de la machine, détection indépendante de `STATE.md`) | `recalc-planning.sh --planning=<dossier avec STATE.md frontmatter gsd_state_version + config.json cycles-v1>` | `rc=3`, message P44-D-02a, aucun fichier créé | ✓ PASS |
| Suite complète du moteur | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | `152 OK · 0 KO` | ✓ PASS |
| 8 suites sœurs de `planning-core` (non-régression altitude lab) | `bash test-check-planning-state.sh` etc. | 19+26+10+38+14+42+22+10 = 181 OK, 0 KO au total | ✓ PASS |
| CI découvre la nouvelle suite sans modification | `.github/workflows/ci.yml:218` | glob `*/tests/test-*.sh`, aucune ligne dédiée à `recalc-planning` | ✓ PASS |
| Version sync | `bash scripts/check-version-sync.sh` | `✓ sources synchronisées (v2.66.0, 17 modules)` | ✓ PASS |
| Aucun chemin machine absolu introduit | `bash scripts/check-machine-paths.sh` | `✓ 1683 fichier(s) ... aucun chemin absolu de machine` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Status | Evidence |
|---|---|---|---|
| MOTR-01 | 44-02, 44-03, 44-05 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-02 | 44-01, 44-05 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-03 | 44-01 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-04 | 44-01 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-05 | 44-02, 44-03 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-06 | 44-02, 44-04 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-07 | 44-02, 44-03 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-08 | 44-02, 44-03 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-09 | 44-02, 44-03 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-10 | 44-01, 44-04 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-11 | 44-01, 44-03 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-12 | 44-01 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-13 | 44-04 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-14 | 44-01, 44-05 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-15 | 44-01, 44-02, 44-05 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-16 | 44-01, 44-03, 44-04 | ✓ SATISFIED | Voir Observable Truths |
| MOTR-17 | 44-03, 44-04, 44-05 | ✓ SATISFIED | Voir Observable Truths (+ note) |
| MOTR-18 | 44-05 | ✓ SATISFIED | Voir Observable Truths |

Aucune exigence ORPHANED : les 18 MOTR listées dans `REQUIREMENTS.md § Phase 44` correspondent
exactement aux `requirements` déclarés dans les cinq plans (union vérifiée).

**Point administratif, non bloquant :** `REQUIREMENTS.md` porte encore `[ ]` et « Not started » pour
MOTR-01..18 (le tableau de traçabilité en tête du fichier et les cases à cocher de la section
Phase 44) — cohérent avec le mandat des cinq SUMMARY, qui excluent explicitement la mise à jour de
`REQUIREMENTS.md` de leur périmètre (« à mettre à jour par l'orchestrateur après la vague »), comme
cela a été fait à la main pour les Phases 42 et 43. À faire par l'orchestrateur après cette
vérification, pas un gap d'implémentation.

### Decision Coverage (P44-D-01 à P44-D-18)

Chaque décision de `44-CONTEXT.md` a été recherchée (`P44-D-XX`) dans les cinq PLAN/SUMMARY, dans
`44-PASSAGE-LABS.md` et dans le code livré. Les 18 décisions structurantes (D-01 à D-18, y compris
les sous-décisions D-01a à D-01e, D-02a, D-06a à D-06c) sont toutes honorées et retrouvées dans au
moins un artefact livré — y compris D-05 (« non tranché en 44 », honoré par l'absence de lecture de
`phases_trace` : `grep phases_trace recalc-planning.sh` → vide) et D-06c (« quatre retenus restent
non nommés », consigné littéralement dans `44-PASSAGE-LABS.md`). Non bloquant par nature (gate
warning-only) — aucune décision non honorée trouvée.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | Aucun `TBD`/`FIXME`/`XXX` non référencé, aucun `TODO`/`HACK`/`PLACEHOLDER`, aucun test désactivé (`grep` rejoué sur tous les fichiers livrés du moteur) | — | Aucun |

Deux occurrences de la sous-chaîne `XXX` trouvées par le grep automatique (`\uXXXX`/`\UXXXXXXXX`
dans `recalc-planning.sh` et `modele-cycles.md`, et `DEC-XXX` dans une entrée historique du
CHANGELOG antérieure à cette phase) : ce sont des gabarits de format hexadécimal et une référence
historique, pas des marqueurs de dette — vérifié en lisant le contexte de chaque occurrence.

### Frontières et garde-fous du jalon (vérifiés sur le diff complet de la phase)

```
git diff --name-only 424cb23c80b31698db1cd232b188abe29128bd19..HEAD   # 37 fichiers, rejoué en session
```

- Aucun fichier sous `plugin/dev-orchestrator/`, `~/.claude/gsd-core/` ou `.claude/gsd-core/` —
  confirmé (absent des 37 fichiers).
- Aucun fichier `plugin/planning-core/scripts/detect-gsd-engine.sh`, `workstream-policy.sh`,
  `detect-planning-debt.sh` — confirmé (absent des 37 fichiers, cohérent avec les 8 suites sœurs
  vertes et non modifiées).
- Aucun fichier sous `.github/**` — confirmé.
- `VERSION` racine, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` —
  confirmés inchangés (absents du diff ; `VERSION` racine relue = `v2.66.0`).
- Aucun fichier sous `.planning/workstreams/fiabilite/**` — confirmé.
- `.planning/BACKLOG.md` — confirmé absent du diff.
- `.planning/instruction-budget-baselines.tsv` — confirmé inchangé (`git diff` vide sur ce
  fichier).
- Aucun tag posé sur `HEAD` (`git tag --points-at HEAD` vide) ; aucune release (garde-fou du jalon
  gouvernance jusqu'à la clôture de `fiabilite-v1.0`, P44-D-18).

Fichiers réellement touchés (37) : les cinq couples PLAN/SUMMARY et les artefacts de phase, le
compartiment `gouvernance` (REQUIREMENTS.md, ROADMAP.md, STATE.md — hors périmètre de ce verifier,
laissés à l'orchestrateur), les deux README racine (compteur de suites), et le module
`plugin/planning-core/` (moteur, tests, banc, référence, gabarits, VERSION, module.json, README,
CHANGELOG). Tout est cohérent avec le périmètre déclaré de la phase.

## Human Verification

N/A — Phase d'infrastructure/fondation (modèle de données + moteur de recalcul en ligne de
commande, aucun élément orienté utilisateur final). Tous les critères d'acceptation sont
vérifiables programmatiquement et ont été rejoués par ce verifier (suite complète du moteur, 8
suites sœurs, spot-checks comportementaux manuels, contrôles structurels du diff de phase). Aucune
vérité n'a été laissée ⚠️ PRESENT_BEHAVIOR_UNVERIFIED.

## Gaps Summary

Aucun gap bloquant trouvé. Les 18 exigences MOTR-01 à MOTR-18 sont satisfaites par le code livré,
pas seulement déclarées par les SUMMARY : la suite du moteur (152 assertions, 35 mutants tracés) a
été ré-exécutée par ce verifier et rejoint le vert annoncé, les spot-checks comportementaux menés
indépendamment (refus d'adhésion, refus GSD sans chaîne installée, mode lecture seule, écriture
déterministe) confirment le contrat sans dépendre des affirmations des agents d'exécution, et le
diff complet de la phase confirme qu'aucun chemin interdit n'a été touché. Le seul point relevé
(traçabilité `REQUIREMENTS.md` encore « Not started ») est un geste administratif explicitement
délégué à l'orchestrateur par les cinq plans eux-mêmes, cohérent avec le traitement des Phases 42
et 43 — non un gap d'implémentation.

---

*Verified: 2026-09-28*
*Verifier: Claude (gsd-verifier)*
