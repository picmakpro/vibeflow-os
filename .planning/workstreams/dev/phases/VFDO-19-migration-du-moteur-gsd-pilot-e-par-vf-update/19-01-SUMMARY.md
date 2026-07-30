---
phase: VFDO-19-migration-du-moteur-gsd-pilotee-par-vf-update
plan: 01
subsystem: infra
tags: [bash, cli-gate, dev-orchestrator, gsd-core, semver-trap, portability]

# Dependency graph
requires: []
provides:
  - "check-gsd-engine.sh : gate de constat à 3 états (absent/legacy/gsd-core), lecture seule, exits 0/2/3"
  - "test-check-gsd-engine.sh : suite dédiée boîte noire, 15 cas, verte macOS + Linux"
affects: [VFDO-19-02, VFDO-19-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Gate advisory read-only sur le modèle check-doc-drift.sh/check-dev-bootstrap.sh (en-tête doc dense, say() sur stderr, printf jamais echo pour le signal)"
    - "Classification par présence de fichier VERSION uniquement — jamais par PATH ni par comparaison de numéro de version (D-05)"
    - "Rupture assumée exit 3 != silence pour le sous-cas dual (D-04), assertions stdout/exit séparées (piège D-14)"

key-files:
  created:
    - plugin/dev-orchestrator/scripts/check-gsd-engine.sh
    - plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh
  modified: []

key-decisions:
  - "D-02/D-03/D-04/D-05 du 19-CONTEXT.md appliqués tels quels, aucune re-négociation"
  - "sanitize_version() borne la lecture à 200 octets (head -c) avant tout traitement, en plus de la validation par liste blanche — durcissement au-delà du modèle check-dev-bootstrap.sh pour couvrir T-19-01-04 (DoS lecture intégrale)"
  - "Le message de proposition de migration évite toute mention littérale de npx/npm/rm -rf dans le code non-commentaire (acceptance criteria Task 1) — la doctrine 'proposer, jamais exécuter' se traduit ici par un renvoi vers /vf-update plutôt que par la commande elle-même"

requirements-completed: [SC1, SC5, SC7]

coverage:
  - id: D1
    description: "Classification à 3 états (absent/legacy/gsd-core) décidée sur la présence de fichier, jamais le contenu"
    requirement: SC1
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh#Cas 1,2,3,4"
        status: pass
    human_judgment: false
  - id: D2
    description: "Contrat de sortie exact 0/2/3 (jamais 1 ni 64), état legacy actionnable en exit 0 avec signal [gsd-migrate]"
    requirement: SC1
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh#Cas 2,11"
        status: pass
    human_judgment: false
  - id: D3
    description: "Cas dual D-04 : gsd-core + reliquat legacy → [gsd-leftover] sur stdout, exit 3 quand même (rupture exit3=silence)"
    requirement: SC1
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh#Cas 4"
        status: pass
    human_judgment: false
  - id: D4
    description: "Aucune comparaison de numéro de version (structurel et comportemental), discriminants 9.9.9/0.0.1"
    requirement: SC5
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh#Cas 5,6,7,8"
        status: pass
    human_judgment: false
  - id: D5
    description: "Scénario réel du rapport (legacy + cache plugin planté à jour) toujours classé legacy, orthogonalité au plugin prouvée"
    requirement: SC5
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh#Cas 9"
        status: pass
    human_judgment: false
  - id: D6
    description: "Robustesse sur VERSION hostile (substitution de commande, octet de contrôle, >80 caractères) sans expansion observable"
    requirement: SC1
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh#Cas 13"
        status: pass
    human_judgment: false
  - id: D7
    description: "Portabilité prouvée par exécution réelle dans un conteneur Linux (ubuntu:24.04), compteur de vertes identique à macOS"
    requirement: SC7
    verification:
      - kind: integration
        ref: "docker run --rm -v \"$(pwd)\":/repo -w /repo ubuntu:24.04 bash plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh"
        status: pass
    human_judgment: false

# Metrics
duration: 15min
completed: 2026-07-28
status: complete
---

# Phase VFDO-19 Plan 01: Détecteur d'état du moteur GSD (check-gsd-engine.sh) Summary

**Gate de constat à 3 états (absent/legacy/gsd-core) qui classe uniquement sur la présence des
fichiers VERSION du poste, jamais sur leur numéro — le legacy `1.42.3` reste actionnable même
face à un gsd-core `0.0.1`, corrigeant le trou semver documenté par l'audit du 2026-07-28.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 3/3 complétées
- **Files modified:** 2 (créés)

## Accomplishments
- `check-gsd-engine.sh` créé : classification à 3 états décidée exclusivement sur la présence des
  fichiers `VERSION` (cascade `default_gsd_home_new()` dupliquée depuis `ensure-deps.sh:60-69`),
  aucune détection PATH, aucune comparaison de numéro de version. Contrat de sortie exact 0/2/3.
- Cas dual D-04 câblé : état `gsd-core` avec reliquat legacy imprime `[gsd-leftover]` sur stdout
  tout en sortant en 3 — rupture assumée et documentée de `exit 3 == silence`.
- `sanitize_version()` assainit toute valeur `VERSION` lue (lecture bornée à 200 octets + liste
  blanche stricte) avant impression — aucune expansion, aucun octet de contrôle, jamais de valeur
  brute réinjectée.
- `test-check-gsd-engine.sh` créé : 15 cas dédiés en boîte noire, couvrant les 3 états, le cas
  dual, les deux discriminants semver (par le haut et par le bas), le scénario réel du rapport
  (legacy + cache plugin planté « à jour »), le discriminant de scope projet-local (miroir T2f de
  `test-dev-orchestrator.sh`), l'erreur d'usage, `--help`/`--quiet`, la robustesse VERSION
  hostile, `bash -n`, la lecture seule par empreinte `find`.
- Portabilité Linux prouvée par exécution réelle (pas par lecture de code) dans un conteneur
  Docker `ubuntu:24.04`.

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Task 1 : tranche traçante — chemin legacy de bout en bout** - `e9a55a1` (feat)
2. **Task 2a (RED) : suite dédiée créée, échec attendu sur le cas dual** - `1116383` (test)
2. **Task 2b (GREEN) : branches absent/gsd-core complétées, cas dual câblé** - `3c77e8a` (feat)
3. **Task 3 : preuve de portabilité Linux** - aucun commit (vérification pure, aucun fichier modifié)

**Plan metadata:** (à suivre — commit final de ce SUMMARY/STATE/ROADMAP)

_Note : Task 2 est `tdd="true"` — deux commits RED puis GREEN, conformément au protocole TDD._

## Files Created/Modified
- `plugin/dev-orchestrator/scripts/check-gsd-engine.sh` — gate de détection, 155 lignes
- `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh` — suite dédiée, 15 cas, 197 lignes

## Decisions Made
- Le message de proposition de migration (`[gsd-migrate]`, 2e ligne) renvoie vers `/vf-update`
  pour confirmation, sans jamais mentionner littéralement `npx`/`npm`/`rm -rf` dans le code — pour
  satisfaire l'acceptance criteria de la Task 1 ("hors commentaires, la source ne contient ni npx,
  ni npm, ni rm -rf") tout en respectant ADR-031 ("proposer, jamais exécuter").
- `sanitize_version()` borne la lecture à 200 octets (`head -c 200`) en amont de toute validation,
  au-delà du modèle strict de `check-dev-bootstrap.sh` (qui valide après lecture complète d'un
  frontmatter déjà borné à 60 lignes) — mitigation directe de T-19-01-04 (lecture intégrale d'un
  fichier VERSION de taille arbitraire).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `mk_gsd_project()` ne capturait pas son paramètre `$1`**
- **Found during:** Écriture de la suite de tests (Task 2, phase RED)
- **Issue:** La fonction utilisait `$name` sans l'avoir déclaré en `local name="$1"`, provoquant
  `unbound variable` sous `set -u` dès le premier appel (bruit sur tous les cas, dont un `mkdir -p
  /.claude` qui a tenté d'écrire hors de la fixture pour le Cas 10).
- **Fix:** Ajout de `local name="$1"` en tête de `mk_gsd_project()`.
- **Files modified:** `plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh`
- **Verification:** Suite rejouée, plus aucune erreur `unbound variable` ni écriture hors fixture ;
  seul le Cas 4 restait KO (RED attendu), conforme au protocole TDD.
- **Committed in:** `1116383` (corrigé avant le commit RED — jamais commité en l'état buggé)

---

**Total deviations:** 1 auto-fixée (Rule 1 — bug de test découvert et corrigé pendant l'écriture
de la suite, avant tout commit).
**Impact on plan:** Aucun écart de périmètre. Correction interne à la suite de tests elle-même,
sans toucher au script ni au contrat.

## Issues Encountered

**Fichier hors périmètre modifié par un processus concurrent.** Pendant l'exécution de ce plan,
`plugin/dev-orchestrator/scripts/ensure-deps.sh` est apparu modifié dans `git status` (probablement
un autre plan de la même phase — 19-02, qui a `ensure-deps.sh` dans son périmètre déclaré au
`19-CONTEXT.md` — exécuté en parallèle sur le même arbre de travail). Ce fichier n'a **jamais** été
lu, édité ni stagé par cet agent : chaque `git add` de ce plan a explicitement nommé
`plugin/dev-orchestrator/scripts/check-gsd-engine.sh` (jamais `git add -A`/`.`), et `git status`
après chaque commit confirme que `ensure-deps.sh` reste non indexé par ce plan. **Signalé
explicitement ici** comme point à faire remonter à l'orchestrateur de phase : deux plans de la
phase 19 semblent partager le même répertoire de travail sans isolation par worktree, ce qui est un
risque de collision si leurs périmètres de fichiers se recouvraient (ce n'est pas le cas ici, les
deux plans ont des fichiers disjoints, mais la coïncidence méritait d'être documentée plutôt que
tranchée silencieusement).

## User Setup Required

None - aucune configuration de service externe requise.

## Preuve de portabilité (Task 3, SC7)

**Commande exacte (exécutée depuis la racine du dépôt) :**
```bash
docker run --rm -v "$(pwd)":/repo -w /repo ubuntu:24.04 bash plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh
```

**Image utilisée :** `ubuntu:24.04` (image de référence demandée par le plan — récupérée sans
repli nécessaire vers `debian:bookworm-slim`).

**Bilan macOS (exécution locale, bash 3.2 host / suite lancée sous bash `#!/usr/bin/env bash`) :**
```
== résultat : 15 ok, 0 ko ==
```

**Bilan conteneur Linux (`ubuntu:24.04`, exit code du `docker run` = 0) :**
```
== test-check-gsd-engine ==
  ✓ 1 état absent → stdout vide, exit 3
  ✓ 2 état legacy (1.42.3) → [gsd-migrate], exit 0
  ✓ 3 état gsd-core seul → stdout vide, exit 3
  ✓ 4 cas dual D-04 → [gsd-leftover], exit 3 (stdout non vide)
  ✓ 5 discriminant D-05 haut : legacy 9.9.9 reste legacy, exit 0
  ✓ 6 discriminant D-05 bas : gsd-core 0.0.1 reste gsd-core, exit 3
  ✓ 7 structurel D-05 : aucun sort -V / newer / comparaison numérique de version hors commentaires
  ✓ 8 documentaire D-05 : en-tête cite 1.42.3, 1.8.0 et semver
  ✓ 9 scénario réel D-11 : legacy + cache plugin « à jour » → migration détectée, orthogonalité prouvée
  ✓ 10 discriminant scope projet-local (miroir T2f) : détecté gsd-core, exit 3
  ✓ 11 argument inconnu → exit 2, stdout vide, stderr non vide (jamais 1 ni 64)
  ✓ 12 --help (exit 0, sortie non vide) et --quiet (stdout identique, stderr vide)
  ✓ 13 robustesse VERSION hostile : rc=0, aucune expansion, aucun octet de contrôle, ligne bornée
  ✓ 14 bash -n passe sur check-gsd-engine.sh
  ✓ 15 lecture seule : empreinte find identique avant/après

== résultat : 15 ok, 0 ko ==
```

**Compteurs identiques (15 ok, 0 ko) macOS et Linux — aucun écart, aucun cas sauté silencieusement.**
`.github/workflows/ci.yml` n'a subi aucune modification (`git diff --name-only` sur les 3 commits
de ce plan ne mentionne que les deux fichiers de `files_modified`).

## Self-Check

- FOUND: plugin/dev-orchestrator/scripts/check-gsd-engine.sh
- FOUND: plugin/dev-orchestrator/scripts/tests/test-check-gsd-engine.sh
- FOUND: e9a55a1 (git log --oneline --all)
- FOUND: 1116383 (git log --oneline --all)
- FOUND: 3c77e8a (git log --oneline --all)

## Self-Check: PASSED

## Next Phase Readiness

`check-gsd-engine.sh` et sa suite sont prêts à être câblés dans `19-03` (branchement sur
`vf-update/SKILL.md`, sonde best-effort dans `<S>`). Le contrat de sortie 0/2/3 et le préfixe
`[gsd-migrate]`/`[gsd-leftover]` sont figés et ne doivent plus changer sans reporter la modification
sur `19-03`. Aucun blocage identifié pour la suite de la phase.

---
*Phase: VFDO-19-migration-du-moteur-gsd-pilotee-par-vf-update*
*Completed: 2026-07-28*
