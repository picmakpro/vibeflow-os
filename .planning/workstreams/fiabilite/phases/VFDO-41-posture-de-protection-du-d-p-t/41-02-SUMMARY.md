---
phase: VFDO-41-posture-de-protection-du-d-p-t
plan: 02
subsystem: infra
tags: [github, codeowners, gitignore-patterns, requirements-ledger, gitops]

# Dependency graph
requires:
  - phase: VFDO-41-posture-de-protection-du-d-p-t
    provides: "41-01 — accès admin constaté (D-02bis), sources JSON des deux rulesets écrites,
      rien posé chez GitHub"
provides:
  - "`.github/CODEOWNERS` : périmètre étroit de D-05 (4 règles, `@picmakpro`), source versionnée
    prête à passer sous revue code owner dès la pose du ruleset de branche (41-05)"
  - "Ledger `REQUIREMENTS.md` amendé : PROT-01 repris (`- [ ]`, non coché), traçabilité
    « Pending — reprise du 2026-09-23 »"
affects: [41-04, 41-05, 41-06, 41-13]

# Actuals (#2632)
actuals:
  tokens: 12000
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "CODEOWNERS : couverture prouvée par témoins positifs ET négatifs via le moteur de motifs
      gitignore de `git check-ignore --no-index`, jamais par lecture visuelle du fichier"

key-files:
  created:
    - .github/CODEOWNERS
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/WINDOWS.md
    - .planning/STATE.md

key-decisions:
  - "PROT-01 est AMENDÉ, jamais recréé : les lignes existantes (dont le motif 'hors d'atteinte —
    2026-09-18') restent octet-identiques ; seules des lignes de suite « Reprise (2026-09-23) »
    sont ajoutées après elles, et la checkbox reste `- [ ]` — cochage réservé au plan 41-13 sur
    pièce (`41-PREUVES.md`)."
  - "L'en-tête de CODEOWNERS ne cite jamais D-01 comme fait (il était faux, `picmakpro` est un
    tiers) — il cite le fait corrigé du 2026-09-23 (`picmakpro` = compte de Willy, admin
    constaté) et D-02bis pour le contournement nommé."
  - "Un rouge préexistant et hors périmètre rencontré au rejeu `gates` (`check-dev-bootstrap.sh`,
    voir Deviations) n'a pas été neutralisé ni corrigé : consigné au ledger
    `.planning/WINDOWS.md` (#8), remonté human_needed, conformément à ADR-031 et au précédent posé
    par le plan 41-01 pour les deux rouges du rejeu `tests`."

requirements-completed: []  # PROT-01 reste NON coché par construction (« coché seulement à la
  # clôture, sur pièce ») ; PROT-04 était déjà coché avant ce plan (clôture antérieure du
  # 2026-09-18 sous l'interprétation sans admin, plan 41-14) — ce plan ne rouvre ni ne referme sa
  # checkbox, il ne fait qu'apporter la source versionnée qui le rendra vérifiable sur pièce après
  # la pose du ruleset (41-05/41-06). `requirements.mark-complete` n'a donc été invoqué pour
  # aucun des deux IDs.

coverage:
  - id: D1
    description: "`.github/CODEOWNERS` à quatre règles exactement (`/.github/`,
      `/.planning/instruction-budget-baselines.tsv`, `/.planning/.*-armed`, `/scripts/hooks/`),
      propriétaire unique `@picmakpro`, en-tête fidèle à la reprise (D-05, D-02bis, fait corrigé,
      lecture sur branche de base, syntaxe sourcée), sans citer D-01"
    requirement: PROT-04
    verification:
      - kind: other
        ref: "Task 1, 1er bloc <automated> (motifs, propriétaire, couverture par témoins positifs
          et négatifs via git check-ignore --no-index, en-tête) et 2e bloc (check-machine-paths.sh)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ledger `REQUIREMENTS.md` amendé : PROT-01 repris (lignes existantes intactes +
      lignes de suite « Reprise (2026-09-23) » ajoutées, checkbox restée `- [ ]`), traçabilité
      PROT-01 remplacée par « Pending — reprise du 2026-09-23 », PROT-02..05 et le reste du
      fichier octet-identiques (une seule ligne retirée : l'ancienne cellule de statut de PROT-01)"
    requirement: PROT-01
    verification:
      - kind: other
        ref: "Task 2, 1er bloc <automated> (comparaison des blocs PROT-01..05 contre le
          merge-base, termes de la reprise présents, diff borné à une ligne retirée)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Aucune proposition du ledger n'associe O-3 à un mot d'achèvement, même nié"
    verification:
      - kind: other
        ref: "Task 2, 2e bloc <automated> (détecteur de co-occurrence O-3 / famille de
          l'achèvement, bornée à la proposition)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Messages de commit du plan citent l'arbitrage attendu avec canal et date
      (D-05/D-02bis pour Task 1, D-02bis pour Task 2)"
    verification:
      - kind: other
        ref: "Task 2, dernier bloc <automated> (contrôle de trace des arbitrages sur la plage de
          commits du plan) — commits_de_plan=9, sans_canal=0"
        status: pass
    human_judgment: false
  - id: D5
    description: "Rejeu `gates` : un rouge rencontré, hors périmètre de ce plan, à l'étape
      « Gates workstream-aware sur un arbre RÉELLEMENT partitionné (fixture jetable) +
      non-régression racine ». Confirmé préexistant (reproduit AVANT toute tâche de ce plan, au
      commit `5488993`) et racine identifiée : le frontmatter de `.planning/STATE.md` dépasse la
      fenêtre de 60 lignes lue par `extract_frontmatter` dans `check-dev-bootstrap.sh` (délimiteur
      fermant à la ligne 61), ce qui rend l'assertion d'invariance R1 non opposable (stdout vide
      des deux côtés). Consigné au ledger (`WINDOWS.md` #8), jamais neutralisé."
    verification:
      - kind: integration
        ref: "replay-ci-jobs.sh --job gates (rc=1, 14 rejouée(s), 1 en échec) ; reproduction
          identique au commit 5488993 (avant toute tâche du plan 41-02, dans ce même worktree) ;
          origin/main cloné isolément n'est PAS affecté (rc=0, 13 étapes) — la cause est la taille
          du frontmatter de STATE.md sur cette branche, pas ce plan"
        status: fail
    human_judgment: true
    rationale: "Réduire le frontmatter de STATE.md (ou modifier la fenêtre de lecture de
      check-dev-bootstrap.sh) est hors du périmètre déclaré de ce plan (`.github/CODEOWNERS`,
      `.planning/REQUIREMENTS.md`) et constitue potentiellement un changement architectural
      (Rule 4) ou touche un outil de gate (Gate-Touche, ADR-072) — aucun des deux ne se corrige
      sans validation humaine (ADR-031, scope boundary de l'exécuteur). Un humain doit trancher
      le remède (compacter STATE.md, ou élargir la fenêtre de lecture du gate) avant que ce
      critère referme au vert."
  - id: D6
    description: "Rejeu `tests` : les deux rouges préexistants déjà documentés par le plan 41-01
      (`test-register-codex-agent-path-traversal.sh` T4, `test-check-description-fidelity.sh`
      PyYAML absent) se reproduisent à l'identique, aucun rouge nouveau"
    verification:
      - kind: integration
        ref: "replay-ci-jobs.sh --job tests (bilan 84 suites, 2 échecs, découverte indépendante
          =84) — mêmes deux fichiers que WINDOWS.md #6/#7, déjà `status=open`, rien de nouveau à
          consigner"
        status: fail
    human_judgment: true
    rationale: "Mêmes rouges que ceux déjà remontés `human_needed` par le plan 41-01 (WINDOWS.md
      #6, #7) — hors périmètre de ce plan, non neutralisés, non déclarés verts."

# Metrics
duration: ~35min
completed: 2026-09-23
status: complete
---

# Phase 41 Plan 02: CODEOWNERS étroit et amendement du ledger Summary

**`.github/CODEOWNERS` posé (4 règles `@picmakpro`, en-tête fidèle à la reprise du 2026-09-23) et
`REQUIREMENTS.md` amendé pour rouvrir PROT-01, sans jamais le déclarer coché ni toucher aux
exigences déjà closes.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-09-23
- **Tasks:** 2/2
- **Files modified:** 4 (1 créé sous `.github/`, 3 mis à jour : `REQUIREMENTS.md`, `WINDOWS.md`,
  `STATE.md`)

## Accomplishments
- `.github/CODEOWNERS` créé : en-tête citant D-05 (Samuel), D-02bis (Willy), le fait corrigé
  (`picmakpro` = Willy, admin constaté le 2026-09-23), l'impossibilité d'auto-approbation, la
  lecture sur branche de base et les deux sources de syntaxe — sans jamais citer D-01. Quatre
  règles exactes (`/.github/`, `/.planning/instruction-budget-baselines.tsv`,
  `/.planning/.*-armed`, `/scripts/hooks/`), propriétaire unique `@picmakpro`. Couverture prouvée
  dans les deux sens par le moteur de motifs gitignore de `git check-ignore` (9 témoins positifs,
  8 témoins négatifs dont la suite de preuve `test-preuve-41-m1.sh` volontairement laissée hors
  CODEOWNERS).
- `REQUIREMENTS.md` amendé, jamais recréé : PROT-01 reste `- [ ]`, ses lignes existantes intactes,
  cinq lignes de suite « Reprise (2026-09-23) » ajoutées (fait corrigé, D-02bis avec canal et
  date, renvois `41-CONTEXT.md`/`41-PREUVES.md`, cochage réservé à la clôture sur pièce). Ligne de
  traçabilité PROT-01 remplacée par « Pending — reprise du 2026-09-23 » ; PROT-02..05 et tout le
  reste du fichier octet-identiques (une seule ligne retirée du fichier : l'ancienne cellule de
  statut de PROT-01).
- Aucune proposition du ledger n'associe O-3 à un mot d'achèvement, même nié.
- Un rouge préexistant et hors périmètre rencontré au rejeu `gates` (étape « Gates
  workstream-aware… », cause : frontmatter de `STATE.md` > 60 lignes lues par
  `check-dev-bootstrap.sh`) confirmé antérieur à ce plan et consigné au ledger `WINDOWS.md` (#8),
  jamais neutralisé.
- Rejeu `tests` : seuls les deux rouges déjà documentés par le plan 41-01 (WINDOWS.md #6, #7) se
  reproduisent, aucun rouge nouveau.

## Task Commits

Each task was committed atomically:

1. **Task 1: `.github/CODEOWNERS` à quatre règles** - `ae20b33` (feat)
2. **Task 2: amendement du ledger — PROT-01 repris** - `0b77f75` (docs)
3. **Consignation ledger d'un rouge préexistant du rejeu gates** - `ff68883` (docs, rattaché à la
   Task 2)

**Plan metadata:** commit à suivre (SUMMARY + STATE + ROADMAP)

## Files Created/Modified
- `.github/CODEOWNERS` - périmètre étroit de revue code owner (D-05), 4 règles `@picmakpro`
- `.planning/REQUIREMENTS.md` - PROT-01 repris (non coché), traçabilité amendée
- `.planning/WINDOWS.md` - entrée #8 (rouge préexistant du rejeu gates, hors périmètre)
- `.planning/STATE.md` - note minimale de reprise du plan 41-02 (Current Position)

## Decisions Made
- L'en-tête de CODEOWNERS ne cite jamais D-01 (faux comme fait) ; seul le fait mesuré le
  2026-09-23 (`picmakpro` = Willy, admin) y figure.
- PROT-01 reste `- [ ]` : ce plan rouvre l'atteignabilité de l'exigence, il ne la clôture pas.
- Le rouge préexistant du rejeu `gates` (workstream-aware, cause STATE.md) n'a pas été corrigé :
  hors périmètre du plan (fichiers modifiés déclarés = CODEOWNERS + REQUIREMENTS.md), potentiel
  changement architectural (Rule 4) ou touche à un outil de gate (Gate-Touche) — ADR-031 impose
  une validation humaine avant tout correctif.

## Deviations from Plan

### Auto-fixed Issues

Aucune — les deux rouges rencontrés (gates, tests) sont hors périmètre et n'ont pas été corrigés
(voir Issues Encountered).

---

**Total deviations:** 0 auto-fixé.
**Impact on plan:** Aucun — les deux tâches déclarées par le plan sont exécutées et vérifiées
telles quelles ; les deux reds environnementaux sont documentés, pas neutralisés, pas comptés
comme des régressions de ce plan.

## Issues Encountered
- Rejeu `gates` (14 rejouée(s), 1 en échec) : l'étape « Gates workstream-aware sur un arbre
  RÉELLEMENT partitionné (fixture jetable) + non-régression racine » rougit sur l'assertion R1
  (`check-dev-bootstrap` racine, stdout vide des deux côtés — « NON OPPOSABLE »). Root cause
  identifiée : `.planning/STATE.md` a un délimiteur de frontmatter fermant à la ligne 61, au-delà
  de la fenêtre de 60 lignes lue par `extract_frontmatter()` dans
  `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` — la lecture est jugée illisible (D-04,
  soupape de sûreté), donc silencieuse dans les deux cas comparés. Confirmé préexistant :
  reproduit à l'identique au commit `5488993` (état exact avant la première tâche de ce plan,
  dans ce même worktree) ; un clone isolé d'`origin/main` n'est PAS affecté (rc=0). Hors périmètre
  déclaré de ce plan (`.github/CODEOWNERS`, `.planning/REQUIREMENTS.md`) ; non corrigé sans
  validation humaine (ADR-031). Consigné `.planning/WINDOWS.md` #8, remonté `human_needed`.
- Rejeu `tests` (bilan 84 suites, 2 échecs, découverte indépendante = 84) : les deux rouges déjà
  documentés par le plan 41-01 (`test-register-codex-agent-path-traversal.sh` T4,
  `test-check-description-fidelity.sh` PyYAML absent) se reproduisent à l'identique — aucun rouge
  nouveau, rien à ajouter au ledger sur ce point (déjà `WINDOWS.md` #6, #7, `status=open`).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `.github/CODEOWNERS` et `REQUIREMENTS.md` sont prêts à être mergés dans `main` (plan 41-04) ;
  la revue code owner ne devient exigible qu'une fois le ruleset de branche posé (41-05) et
  CODEOWNERS lu sur la branche de base après ce merge.
- PROT-01 reste non coché — cochage réservé au plan 41-13, sur pièce (`41-PREUVES.md`).
- Trois rouges préexistants et hors périmètre restent ouverts au ledger (`WINDOWS.md` #6, #7, #8)
  — à trancher par un humain avant toute clôture de phase qui exigerait `gates rc=0` et
  `tests rc=0` littéraux.

---
*Phase: VFDO-41-posture-de-protection-du-d-p-t*
*Completed: 2026-09-23*

## Self-Check: PASSED
- `.github/CODEOWNERS` : FOUND
- `.planning/REQUIREMENTS.md` (PROT-01 amendé) : FOUND
- `.planning/WINDOWS.md` (entrée #8) : FOUND
- Commits `ae20b33`, `0b77f75`, `ff68883` : FOUND dans `git log`
