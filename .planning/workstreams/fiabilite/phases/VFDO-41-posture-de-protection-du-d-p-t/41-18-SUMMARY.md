---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 18
subsystem: docs
tags: [adr, doctrine, backlog, security, gouvernance]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t (plans 41-14, 41-16, 41-17)
    provides: "les trois gardes livrées (scripts/check-baseline-arbitrage.sh,
      scripts/check-gate-touche.sh, scripts/check-push-sans-pr.sh) et leurs verdicts réels,
      recopiés dans ADR-072 depuis les SUMMARY existants et, pour G-2 (41-16, dont le SUMMARY
      n'existe pas), depuis l'en-tête du script et le CHANGELOG"
provides:
  - "docs/ADR.md — ADR-072 « Gardes in-repo sans règle côté serveur » + ligne d'index après
    ADR-070"
  - "CLAUDE.md — section « Gardes in-repo — ce qui est gardé, ce qui ne l'est pas », convention
    du trailer Gate-Touche:"
  - ".planning/BACKLOG.md — deux lignes de statut Phase 41 + une entrée courte pour l'absence
    de ligne d'index ADR-071"
  - "25-SECURITY.md — observation O-3 portée à « signalée et tracée »"
affects: [41-19]

# Actuals
actuals:
  tokens: null
  tasks: 3
  commits: 3
  plan_head_before: 7bd4fdb

tech-stack:
  added: []
  patterns:
    - "Recopie des verdicts réels depuis les scripts et le CHANGELOG quand un SUMMARY manque
      (41-16-SUMMARY.md n'a jamais été produit, confirmé absent de tout l'historique) — jamais
      l'intention du plan d'origine"

key-files:
  created: []
  modified:
    - docs/ADR.md
    - CLAUDE.md
    - .planning/BACKLOG.md
    - .planning/phases/VFDO-25-budget-d-instructions-et-tage-d-alignement-court/25-SECURITY.md

key-decisions:
  - "Aucun arbitrage de fond rouvert : ce plan écrit la doctrine des décisions déjà arbitrées par
    le manager le 2026-09-17 (périmètre sans admin, bornes de G-1, création de PROT-05)."
  - "41-16-SUMMARY.md confirmé absent de tout l'historique (git log --oneline --all) : G-2 décrite
    dans ADR-072 et CLAUDE.md à partir de l'en-tête de scripts/check-gate-touche.sh et de l'entrée
    CHANGELOG.md § Non releasé — zone grise signalée, non résolue en silence."

requirements-completed: [PROT-03, PROT-04]

coverage:
  - id: D1
    description: "ADR-072 : ligne d'index unique après ADR-070, section unique, ADR-071 intacte,
      aucune ligne d'index ADR-071 ajoutée, trois gardes nommées et décrites d'après les livrables
      réels, cinq renvois obligatoires, trois motifs du 2026-09-17"
    requirement: PROT-03
    verification:
      - kind: other
        ref: "verify automated Task 1 du plan 41-18 (deux blocs awk) — index_ADR072=1
          section_ADR072=1 section_ADR071_intacte=1 ancre_ADR070_existe=1 ADR072_suit_ancre=oui
          index_ADR071_ajoute=0 ; gardes_nommees=3 renvois_obligatoires=5 motifs_2026-09-17=3
          lignes=118"
        status: pass
    human_judgment: false
  - id: D2
    description: "CLAUDE.md : section unique, trois gardes nommées par chemin concret, trailer et
      limite de fond présents, sections existantes intactes, check-map-drift.sh en 0 ou 3"
    requirement: PROT-03
    verification:
      - kind: other
        ref: "verify automated Task 2 — section=1 gardes=3 trailer=1 regle_release_intacte=1
          tracabilite_intacte=1 ; check-map-drift.sh --path . rc=0"
        status: pass
    human_judgment: false
  - id: D3
    description: "BACKLOG.md : deux statuts Phase 41 ajoutés sans réécriture, renvoi ADR-072,
      constat ADR-071 avec déclencheur ; O-3 nommant G-1/G-2, statut « signalée et tracée »,
      T-25-16 et O-4 intactes"
    requirement: PROT-04
    verification:
      - kind: other
        ref: "verify automated Task 3 — statuts_phase41=2 items_intacts=2 renvois_ADR072=4
          constat_index_ADR071=1 declencheur=1 ; O3 gardes=2 statut_signalee_tracee=2
          ligne_T-25-16_intacte=1 O-4_intacte=1"
        status: pass
    human_judgment: false
  - id: D4
    description: "Aucun mot d'achèvement associé à une garde ou à O-3 dans tout texte produit par
      ce plan"
    requirement: PROT-04
    verification:
      - kind: unit
        ref: "tools/check-aucune-fermeture.sh rejoué après CHAQUE tâche — rc=0 les trois fois"
        status: pass
    human_judgment: false
  - id: D5
    description: "Rejeu complet des deux jobs CI après le plan"
    verification:
      - kind: integration
        ref: "tools/replay-ci-jobs.sh --job gates (13 étapes rejouées, 3 sautées, 0 échec, rc=0) ;
          --job tests (1 étape rejouée, 5 sautées, 0 échec, rc=0, bilan 82 suites 0 échec)"
        status: pass
    human_judgment: false

status: complete
completed: 2026-09-18
---

# Phase VFDO-41 Plan 18: G-4 — doctrine (ADR-072, CLAUDE.md, BACKLOG, O-3) Summary

**Écrit la doctrine du périmètre sans admin de la Phase 41 : ADR-072 dans `docs/ADR.md` (ce qui
est gardé par G-1/G-2/G-3, ce qui ne l'est pas, ce qui attend un accès admin), un résumé dense dans
`CLAUDE.md`, deux renvois de statut dans `.planning/BACKLOG.md` plus une entrée courte pour
l'absence de ligne d'index ADR-071, et l'observation O-3 du `25-SECURITY.md` portée à « signalée
et tracée ». Aucun script modifié, aucun arbitrage de fond rouvert.**

## Performance

- **Tâches :** 3/3 complétées
- **Fichiers modifiés :** 4 (`docs/ADR.md`, `CLAUDE.md`, `.planning/BACKLOG.md`, `25-SECURITY.md`)
- **Commits :** 3

## Accomplissements

- `docs/ADR.md` : ligne d'index ADR-072 insérée immédiatement après la ligne ADR-070 mesurée
  (la table s'arrêtait là, ADR-071 n'y a jamais eu de ligne — non corrigée ici, hors périmètre) ;
  section ADR-072 complète (Contexte ; ce qui est gardé — G-1/G-2/G-3 décrites d'après les
  SUMMARY et scripts livrés ; les deux bornes de G-1 avec leur motif ; l'exigence PROT-05 ; ce qui
  n'est pas gardé ; ce qui attend un accès admin ; politique de contournement PROT-03 ; compatibilité
  du flux de release PROT-02).
- `CLAUDE.md` : section « Gardes in-repo — ce qui est gardé, ce qui ne l'est pas » après
  « Conventions transverses », les trois gardes nommées par leur chemin concret (aucun glob entre
  accents graves), convention du trailer `Gate-Touche:`, règle de citation d'arbitrage sur une
  hausse de baseline, limite de fond. `check-map-drift.sh --path .` rc=0, aucune divergence
  nouvelle introduite (les trois divergences pré-existantes — `docs`, `manual`, `reports` — sont
  antérieures à ce plan).
- `.planning/BACKLOG.md` : deux lignes `**Statut partiel (2026-09-18, Phase 41) :**` ajoutées sous
  les deux items concernés, sans réécriture d'aucune ligne existante ; une entrée courte consigne
  l'absence de ligne d'index ADR-071, hors périmètre, avec son déclencheur de reprise.
- `25-SECURITY.md` : le corps de l'observation O-3 réécrit — garde ce qui reste vrai (aucune
  protection côté serveur, le gate rend 0 sur une baseline relevée à la main), ajoute ce qui a
  changé (G-1 et G-2 signalent désormais une hausse non citée et une modification de la surface de
  gate), statut « signalée et tracée » en toutes lettres, renvoi à ADR-072. La ligne STRIDE
  `T-25-16` et l'observation O-4 restent intactes (vérifié par le verify machine).
- Recensement `tools/check-aucune-fermeture.sh` rejoué après chaque tâche : rc=0 les trois fois.
- Contrôle de trace `tools/check-trace-arbitrage.sh` : rc=0.
- Rejeu complet des deux jobs CI : `gates` rc=0 (13 étapes rejouées, 3 sautées — dont
  `check-push-sans-pr` mesure réelle et `check-release-tag`, tous deux conditionnels `main` —, 0
  échec) ; `tests` rc=0 (1 étape rejouée, 5 sautées infra runner, 0 échec, bilan 82 suites/0 échec).

## Task Commits

1. **Task 1 : ADR-072 et sa ligne d'index** — `9d5e18b` (docs)
2. **Task 2 : résumé dans CLAUDE.md** — `eb97f9c` (docs)
3. **Task 3 : BACKLOG par renvoi, O-3 « signalée et tracée »** — `6bbee55` (docs)

_Base (`plan_head_before`) : `7bd4fdb` (dernier commit de 41-17-SUMMARY). `commits` mesuré
(`git rev-list --count 7bd4fdb..HEAD`) : 3._

## Files Modified

- `docs/ADR.md` — ADR-072 (ligne d'index + section)
- `CLAUDE.md` — section « Gardes in-repo — ce qui est gardé, ce qui ne l'est pas »
- `.planning/BACKLOG.md` — deux statuts Phase 41 + une entrée courte (index ADR-071)
- `25-SECURITY.md` — O-3 réécrite

## Decisions Made

Aucune décision de fond nouvelle : ce plan documente des arbitrages déjà tranchés par le manager
le 2026-09-17 (périmètre sans admin option (a), bornes de G-1, création de PROT-05). Voir
`key-decisions` en frontmatter.

## Deviations from Plan

Aucune déviation de fond. Une zone grise signalée ci-dessous (absence de `41-16-SUMMARY.md`).

## Zones grises (jugements explicites, non résolus en silence)

1. **`41-16-SUMMARY.md`, cité en `<context>` du plan 41-18, absent de tout l'historique du
   dépôt.** Confirmé par le même constat que fait `41-17-SUMMARY.md` (§ Zones grises 5) :
   `git log --oneline --all -- '*41-16-SUMMARY.md*'` ne rend rien. Le plan 41-16 (G-2) n'a jamais
   produit ce fichier lors de son exécution, malgré ses trois commits (`9d7d461` feat, `633be34`
   test, `c9439f1` feat — vérifiés par `git log --oneline --grep="41-16"`). J'ai reconstruit la
   description de G-2 pour
   ADR-072 et `CLAUDE.md` à partir de deux sources directement mesurées : l'en-tête complet de
   `scripts/check-gate-touche.sh` (contrat de sortie, cinq classes de surface, portée branche,
   formule canonique de limite de fond déjà écrite dans le script lui-même) et l'entrée
   `CHANGELOG.md` § Non releasé consacrée à G-2 — jamais l'intention du plan 41-16. À signaler au
   manager : un SUMMARY manquant pour 41-16 reste un trou dans la trace de la phase, indépendant de
   ce plan 41-18.
2. **Orchestration de plan unique dans une phase à waves collisionnées.** Le skill
   `gsd-execute-phase` n'offre pas de filtre par identifiant de plan (`--wave N`,
   `--gaps-only`, `--interactive` seulement) ; sa vue `init.execute-phase` liste 16 plans
   incomplets, dont les plans 41-01 à 41-13 (différés, accès admin requis, hors périmètre de ce
   mandat) qui partagent leurs numéros de wave (1 à 13) avec les plans 41-14 à 41-19 (wave 1 à 6).
   Utiliser `--wave 5` aurait sélectionné à la fois 41-18 (visé) et 41-05 (différé, hors périmètre,
   impossible sans admin). Exécuté le plan 41-18 directement, tâche par tâche, en suivant à la
   lettre son `<action>` et en rejouant chacun de ses `<verify>` — c'est le geste que
   `gsd-executor` aurait fait pour ce seul plan dans une wave dédiée. Aucune réimplémentation de
   logique d'outil : les commandes de verify sont celles écrites dans le plan, exécutées telles
   quelles.

## Issues Encountered

Aucune non documentée ci-dessus.

## User Setup Required

None.

## Limite de fond

Formule canonique (sonde de limite de fond, `check-aucune-fermeture.sh`, plan 41-15, mandat élargi
du manager de mission, 2026-09-17), reprise ici mot pour mot pour que la sonde ne signale plus ce
SUMMARY comme muet sur la limite de fond des trois gardes qu'il documente : chacune des trois
gardes (G-1, G-2, G-3) peut être modifiée par la PR qu'elle juge — aucune règle côté serveur
n'existe, sur ce dépôt, pour l'en empêcher.

## Next Phase Readiness

- La doctrine du périmètre sans admin est complète et tracée : ADR-072, résumé `CLAUDE.md`, deux
  renvois BACKLOG, O-3 « signalée et tracée ».
- Le plan 41-19 (clôture, ledger) peut s'appuyer sur cette doctrine sans en rouvrir aucune partie.
- Aucun blocage connu pour 41-19.

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Plan: 18*
*Completed: 2026-09-18*

## Self-Check: PASSED

Fichiers vérifiés modifiés : `docs/ADR.md`, `CLAUDE.md`, `.planning/BACKLOG.md`, `25-SECURITY.md`.
Commits vérifiés présents dans l'historique : `9d5e18b`, `eb97f9c`, `6bbee55`.
