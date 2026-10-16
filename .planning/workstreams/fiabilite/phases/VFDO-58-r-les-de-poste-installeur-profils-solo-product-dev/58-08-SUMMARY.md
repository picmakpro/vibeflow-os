---
phase: 58-r-les-de-poste-installeur-profils-solo-product-dev
plan: 08
status: complete
requirements: [RLPO-06, RLPO-07]
commits: [423405e8 (correctifs de revue), aa56ce6d (volet usage)]
---

# 58-08 — volet usage de l'engine (filtre, registre, verbe role)

Arbitrages : P58-D-01..14, arbitrage Samuel, AskUserQuestion session principale, 2026-10-16.

## Réalisé
- `find_module_roles`, `role_visible`, `role_notice`, verbe `role` dans `plugin/_internal/vibeflow-update.sh` ;
  `gitignore_add_paths()` inchangée (P58-D-13).
- Journal du filtre (stderr) : `[vibeflow-update]   [poste] mobile-test hors de la vue du poste product : non posé`.
- Avis exact de RV-ROLE-1 (stdout) :
  `Poste : product — un poste est une vue, pas un droit.` /
  `Avis : 1 module(s) installé(s) hors du poste product, conservé(s) — aucune désinstallation (ADR-031) :` /
  `  - mobile-test`.
- Registre sans ligne de poste : RV-REG contrôle 36 runs ; `update --all` ne lit pas le poste (RV-UPDATE).

## Mutants tués (copie de `_internal/`, attendu/obtenu dans la suite)
RV-M3 filtre neutralisé (saute -> pose) ; RV-M5 `role=` au registre (0 -> 1 ligne) ;
RV-M6 avis amputé (liste -> amputé) ; RV-M1, M2, M4, M7 de 58-06 toujours tués.

## Bilans et durées
- `test-vibeflow-update-role.sh` : 35 OK / 0 KO, 30 s (bash courant et /bin/bash 3.2).
- `test-vibeflow-update.sh` (non modifié) : 93 OK / 0 KO / 0 SKIP, 126 s.
- `test-manifest.sh` 62/0 ; `test-resolve-deps.sh` 5/0 ; `test-module-roles.sh` 19/0 ; `test-merge-hooks.sh` 39/0.

## Écarts
- Correctifs de revue (commit 423405e8) joués avant : garde `! -L`, motif du lecteur, empreinte épinglée du
  catalogue gelé, outillage absent -> code 5 (filet EXIT, bloc canonique intact).
- `role solo` en scope user est refusé comme les autres postes (le verbe n'a pas de sens en scope user).
- `mk_lab` copie désormais mobile-test au cache de la suite (RV-ALL-1 l'exige).
