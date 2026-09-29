---
phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator
plan: 02
subsystem: infra
tags: [gate, skills, frontmatter, dérive, prose-detection, bash, python, mutation-testing]

# Dependency graph
requires:
  - phase: 43-01
    provides: "check-skills.sh (gate des skills par nature, FABR-06), contrat de clés VIBEFLOW_SKILL_FIELDS, harnais make_gate_mutant/okmut/komut"
  - phase: 43-03
    provides: "skill-creator/SKILL.md et skill-creator-workflow/SKILL.md posent vf-nature (FABR-08) — corpus mesuré ici les inclut dans leur état final"
provides:
  - "detecter_derive() : écart déclaration/prose dans les deux sens, par marqueur, selon la règle Q-PORTEE — toujours un avertissement, jamais un refus (FABR-07, D-Q1, D-Q5)"
  - "ecart_nature_marqueurs() : marqueur déclaré true et vf-nature != procedure -> avertissement citant B-03/C-15, nature jamais réécrite ni déduite"
  - "vocabulaire MOTIFS_MARQUEURS documenté dans l'en-tête du script (décision de plan, costly)"
  - "corpus réel mesuré et publié (26 avertissements « derive » sur 11 SKILL.md/21, 0 « ecart »), corpus laissé non corrigé (backlog e36e6f2)"
affects: [43-06, 43-07]

# Actuals (#2632)
actuals:
  tokens: 6923
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Règle Q-PORTEE : un marqueur constaté par titre (seuil 1) ou par au moins deux marqueurs DISTINCTS en prose (seuil 2), même définition lue par les deux sens (patron invariant_i1 de check-agents.sh)"
    - "lignes_de_portee()/marqueurs_constates() calculent le résultat UNE fois ; detecter_derive() le lit pour les deux sens, jamais un recalcul ni un seuil propre à un sens"
    - "Avertissement structurel garanti (D-Q5) : appel unique warnings.extend(...) par détecteur, jamais errors.extend(...) — prouvé par mutation (MUT-DR2 promeut en erreur, trace capturée)"

key-files:
  modified:
    - plugin/conductor/scripts/check-skills.sh
    - plugin/conductor/scripts/tests/test-check-skills.sh

key-decisions:
  - "Vocabulaire MOTIFS_MARQUEURS (décision de plan, costly, 43-RESEARCH.md Pitfall 2) : trois regex par marqueur, données littéralement par le plan — vf-gate-bloquant (gate/bloquant), vf-livrable-tiers (livrable/remis à/destinataire), vf-couche-qualite (juge/rubrique/grille qualifiée/checklist qualité/couche de jugement-qualité-audit/quality gate)"
  - "Règle Q-PORTEE tranchée en amont du plan (décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26) : un marqueur en titre, OU au moins deux marqueurs distincts en prose — jamais un mot isolé en prose, jamais dans le frontmatter ni un bloc de code délimité"
  - "Écart de nature (B-03, C-15) : la nature n'est jamais réécrite ni déduite depuis les marqueurs — seul un avertissement signale l'incohérence, laissée à l'auteur du skill"
  - "Corpus réel laissé non corrigé (D-Q5, écart assumé vis-à-vis de D-11 Phase 42) : les 26 avertissements mesurés alimentent l'entrée de backlog e36e6f2 (vf-dev-manager), aucun SKILL.md du corpus modifié par ce plan"

patterns-established:
  - "Détecteur en deux sens sur un résultat unique : toute future détection croisée déclaration/corps doit lire une seule fonction de constat (ici marqueurs_constates), jamais recalculer par sens"

requirements-completed: [FABR-07]

coverage:
  - id: D1
    description: "detecter_derive() signale l'écart déclaration/prose dans les deux sens, par marqueur, selon la règle Q-PORTEE, toujours en avertissement (jamais un refus, y compris sous --strict)"
    requirement: "FABR-07"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-skills.sh#T22-T29,T26a-T26h,MUT-DR1,MUT-DR2"
        status: pass
    human_judgment: false
  - id: D2
    description: "ecart_nature_marqueurs() signale un marqueur déclaré true avec une nature autre que procedure, sans jamais réécrire ni déduire la nature"
    requirement: "FABR-07"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-skills.sh#T30,T31,MUT-DR3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Corpus réel (21 SKILL.md hors plugin/reference) mesuré sous --strict, reste vert (rc 0), liste complète des avertissements publiée dans ce SUMMARY pour alimenter le backlog de mise en conformité"
    verification:
      - kind: integration
        ref: "plugin/conductor/scripts/tests/test-check-skills.sh#T32"
        status: pass
      - kind: other
        ref: "CORPUS-DERIVE fail=0 avertissements=26 (commande de vérification du plan, rejouée)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Aucun SKILL.md du corpus modifié par ce plan (hors les deux fichiers déjà touchés par 43-03 et la ligne de vf-calibrate de 43-06)"
    verification:
      - kind: other
        ref: "git diff --name-only <base-de-phase> HEAD -- 'plugin/*SKILL.md' (exclusions skill-creator/*, vf-calibrate/*) — vide"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-09-26
status: complete
---
Base du plan : 450ab9c6317193ccf2d6bf10566a10fa41866062

# Phase 43 Plan 02: Détection de dérive procédurale en écart (D-Q1) et mesure du corpus réel (FABR-07) Summary

**`detecter_derive()`/`ecart_nature_marqueurs()` ajoutés à `check-skills.sh` : écart déclaration/prose et déclaration/nature signalés en avertissement seul selon la règle Q-PORTEE, corpus réel mesuré (26 avertissements sur 11/21 SKILL.md), laissé non corrigé.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-09-26 (HEAD 450ab9c)
- **Completed:** 2026-09-26
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `detecter_derive(rel, fm, lignes)` : lit `marqueurs_constates(lignes_de_portee(texte))` UNE fois pour les deux sens (patron `invariant_i1` de `check-agents.sh`) — marqueur constaté (titre, ou ≥2 marqueurs distincts en prose) et déclaration absente/false -> « derive » ; déclaration `true` et marqueur non constaté -> « ecart ». Toujours `warnings.extend(...)`, jamais `errors.extend(...)` (D-Q5, prouvé par MUT-DR2 avec trace).
- Règle Q-PORTEE codée par `lignes_de_portee()` (portée hors frontmatter et hors blocs de code délimités, accents graves ou tildes) et les constantes `DERIVE_TITRE_MIN = 1` / `DERIVE_PROSE_MIN_DISTINCTS = 2`, vocabulaire `MOTIFS_MARQUEURS` documenté dans l'en-tête du script.
- `ecart_nature_marqueurs(rel, fm)` (Tâche 2) : au moins un marqueur déclaré `true` avec `vf-nature` différente de `procedure` (absente comptée `outil`) -> avertissement citant B-03/C-15 ; la nature reste déclarée, jamais réécrite ni déduite.
- 18 cas de test ajoutés (T22 à T29, T26a à T26h, T30 à T32) et trois mutants tués (MUT-DR1, MUT-DR2 avec trace de déplacement ⚠→✗, MUT-DR3 avec trace de comptage de message) — `test-check-skills.sh` passe de 53 à 74 cas verts, 0 KO.
- Corpus réel (21 SKILL.md hors module doc-only `plugin/reference`) mesuré sous `--strict` : reste vert (`CORPUS-DERIVE fail=0`), 26 avertissements « derive » sur 11 SKILL.md, 0 « ecart » (aucun marqueur encore déclaré `true` dans le corpus) — liste complète ci-dessous, publiée pour le backlog e36e6f2. Aucun SKILL.md du corpus modifié.

## Task Commits

Chaque tâche a été commitée atomiquement :

1. **Tâche 1 : dérive en écart, dans les deux sens, par marqueur, selon la règle Q-PORTEE (T22-T29, MUT-DR1, MUT-DR2)** - `29f2529` (feat)
2. **Tâche 2 : écart nature ↔ marqueurs, mesure et publication du corpus réel (T30-T32, MUT-DR3)** - `ac0147a` (feat)

**Plan metadata:** ce fichier + STATE/ROADMAP/REQUIREMENTS sont commités par l'orchestrateur après la vague (mandat de dispatch : ne pas toucher STATE.md/ROADMAP.md).

## Files Created/Modified

- `plugin/conductor/scripts/check-skills.sh` — `detecter_derive`, `ecart_nature_marqueurs`, `lignes_de_portee`, `marqueurs_constates`, `MOTIFS_MARQUEURS`, constantes `DERIVE_PROSE_MIN_DISTINCTS`/`DERIVE_TITRE_MIN`, en-tête étendu (section « Détection de dérive », citation de la règle Q-PORTEE, mesure du corpus)
- `plugin/conductor/scripts/tests/test-check-skills.sh` — T22 à T29 (T26a-T26h), T30 à T32, MUT-DR1, MUT-DR2, MUT-DR3

## Decisions Made

Voir `key-decisions` en frontmatter (vocabulaire MOTIFS_MARQUEURS, règle Q-PORTEE déjà tranchée en amont dans le PLAN.md, écart de nature jamais déductif, corpus laissé non corrigé). Aucune décision nouvelle prise pendant l'exécution — le vocabulaire et la règle sont donnés littéralement par 43-02-PLAN.md (action Tâche 1, étape 2) et le bloc de contexte du plan (règle Q-PORTEE tranchée tour 4, 2026-09-26).

## Deviations from Plan

None - plan exécuté exactement comme écrit. Un ajustement purement rédactionnel a été fait pendant le développement (avant tout commit) : les premières versions des commentaires d'en-tête citaient littéralement le motif ciblé par MUT-DR1/MUT-DR2/MUT-DR3 (`warnings.extend(detecter_derive(` / `warnings.extend(ecart_nature_marqueurs(`), ce qui rendait le motif non unique dans le fichier (`make_gate_mutant` exige exactement 1 occurrence). Reformulé sans reproduire le motif littéral avant le premier commit — n'a jamais été committé sous sa forme ambiguë, donc non listé comme déviation au sens des Règles 1-4 (aucun code livré n'était en cause).

## Issues Encountered

None.

## Corpus réel mesuré sous la règle Q-PORTEE (CORPUS-DERIVE, 2026-09-26)

Mesure exécutée après le commit de la Tâche 2, avec le gate final (`detecter_derive` + `ecart_nature_marqueurs`), sur les 21 SKILL.md hors module doc-only (`plugin/reference` exclu). `DERIVE_PROSE_MIN_DISTINCTS = 2`, `DERIVE_TITRE_MIN = 1` (règle Q-PORTEE, décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26). Commande de vérification du plan rejouée : `CORPUS-DERIVE fail=0 avertissements=26`.

**11 SKILL.md sur 21 en dérive** (0 « ecart » — aucun des trois marqueurs n'est encore déclaré dans le corpus) :

| SKILL.md | Marqueur(s) en titre | Marqueur(s) en prose |
|---|---|---|
| `plugin/audit-architecture/SKILL.md` | vf-couche-qualite (« Le primitif universel : la couche d'audit ») | vf-gate-bloquant (« Iron Law… ») |
| `plugin/business-pilot-bundle/skills/vf-business/SKILL.md` | — | vf-gate-bloquant, vf-livrable-tiers, vf-couche-qualite |
| `plugin/conductor/skills/vf-new-lab/SKILL.md` | vf-gate-bloquant (« Phase 3 — Gate A ») | vf-livrable-tiers, vf-couche-qualite |
| `plugin/content-bundle/skills/vf-content/SKILL.md` | — | vf-gate-bloquant, vf-livrable-tiers, vf-couche-qualite |
| `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` | — | vf-gate-bloquant, vf-livrable-tiers |
| `plugin/growth-bundle/skills/vf-growth/SKILL.md` | — | vf-gate-bloquant, vf-livrable-tiers, vf-couche-qualite |
| `plugin/mobile-test/SKILL.md` | vf-couche-qualite (« Couche jugement : diagnostic sur échec ») | — |
| `plugin/planning-core/SKILL.md` | — | vf-gate-bloquant, vf-livrable-tiers |
| `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` | vf-gate-bloquant (« Phase 5 — Escalation… (BLOQUANT) »), vf-couche-qualite (« Checklist qualite ») | vf-livrable-tiers |
| `plugin/skill-creator/skills/skill-creator/SKILL.md` | — | vf-gate-bloquant, vf-livrable-tiers, vf-couche-qualite |
| `plugin/software-architecture/SKILL.md` | vf-gate-bloquant (« Tier 1 — Gate local ») | — |

**Écart avec la mesure de planification du bloc de contexte (10/21, 2026-09-26)** : +1 fichier — `plugin/skill-creator/skills/skill-creator/SKILL.md` n'était pas en dérive à la planification (aucun marqueur), mais 43-03 (exécuté avant ce plan, selon `depends_on`) y a ajouté les trois questions factuelles vf-nature en prose (§ « Write the SKILL.md », lignes 55-57 et 72-76 du fichier), qui contiennent désormais les trois marqueurs distincts en prose (« blocking gate », « deliverable to a third party », « quality layer (a judge, a rubric) », « vf-rubrique-juge »). C'était anticipé littéralement par ce plan (bloc de contexte, dernier paragraphe : « le moteur interne, sans marqueur aujourd'hui, passera vraisemblablement en dérive »). Les 10 autres fichiers et leurs marqueurs correspondent exactement à la mesure de planification. `plugin/skill-creator/skills/skill-creator-workflow/SKILL.md` était déjà compté dans les 10.

**Aucun SKILL.md du corpus n'a été modifié par ce plan** — la mise en conformité (déclarer les marqueurs ou reformuler la prose) reste au backlog `.planning/BACKLOG.md` (entrée « Mise en conformité du corpus de skills en dérive procédurale non déclarée », posée par vf-dev-manager le 2026-09-24, commit `e36e6f2`), conformément à D-Q5 (Willy, AskUserQuestion, 2026-09-24/26) : ce plan avertit, il ne corrige pas.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `detecter_derive()` et `ecart_nature_marqueurs()` sont posés et stables ; le vocabulaire `MOTIFS_MARQUEURS` et la règle Q-PORTEE sont figés dans l'en-tête du script — tout futur ajustement du vocabulaire doit rester cohérent avec les questions factuelles posées par `skill-creator` (43-03) et l'initialisation d'un lab (C-15), sous peine de rupture outil ↔ déclaration (reversibility costly, notée dans le PLAN).
- `requirements.mark-complete` n'a PAS été appelé par cet exécuteur (mandat de dispatch : ne pas toucher STATE.md/ROADMAP.md/REQUIREMENTS.md, l'orchestrateur les met à jour après la vague — même précédent que 43-01/43-03/43-04/43-05).
- Le backlog de mise en conformité du corpus (entrée `e36e6f2`) peut désormais être repris avec la liste précise de ce SUMMARY (11 fichiers, 26 avertissements) — déclencheur de reprise déjà noté dans `STATE.md` du compartiment `gouvernance`.
- 43-06 et 43-07 (vagues suivantes) peuvent s'appuyer sur `detecter_derive`/`ecart_nature_marqueurs` sans réouvrir ce contrat.

---
*Phase: 43-fabrique-gate-des-skills-par-nature-et-alignement-de-skill-creator*
*Completed: 2026-09-26*

## Self-Check: PASSED

- Fichiers modifiés présents sur disque et cohérents : `plugin/conductor/scripts/check-skills.sh`, `plugin/conductor/scripts/tests/test-check-skills.sh` — tous trouvés, `bash -n` réussit sur les deux.
- Commits trouvés dans `git log --oneline` : `29f2529` (Tâche 1), `ac0147a` (Tâche 2).
- `bash plugin/conductor/scripts/tests/test-check-skills.sh` : 74 OK · 0 KO (T1 à T32 dont T26a-T26h, dix mutants dont MUT-DR1/DR2/DR3 tués avec trace).
- Toutes les `<acceptance_criteria>` des deux tâches rejouées vertes : `warnings.extend(detecter_derive(`/`errors.extend(detecter_derive(` (1/0), `MOTIFS_MARQUEURS` (3), constantes `DERIVE_PROSE_MIN_DISTINCTS`/`DERIVE_TITRE_MIN`, citation Q-PORTEE (1), `marqueurs_constates(` (4), `warnings.extend(ecart_nature_marqueurs(` (1), zéro appel `make_gate_mutant` en substitution de commande.
- `PREMIER-COMMIT-G2 29f2529d0fb210cb1049209d9b211769f9d372ad` sans aucune ligne NON-COUVERT/GIT-ECHEC/AUCUN-COMMIT-G2/BASE-ABSENTE.
- `CORPUS-DERIVE fail=0 avertissements=26` rejoué avec succès ; base de phase figée (`22179fa5`) toujours ancêtre de HEAD, aucun SKILL.md du corpus touché hors exclusions attendues (skill-creator/*, vf-calibrate/*).
