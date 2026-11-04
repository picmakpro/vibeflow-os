# 68-02 — SUMMARY (VFSG-05, volet socle ; P68-D-04)

Retard sur la branche de base (local et `origin/<base>` local, âge du dernier fetch), worktrees avec branche, phase active : calculés sans réseau.
Trace du rouge : `68-02-RED-TRACE.md`.

## Commits

| SHA | Rôle |
|-----|------|
| `f27cc32a` | A — suite `test-cockpit-retard.sh`, 30 FAIL sur 38 (module absent) |
| `2c5e5ab0` | B — `68-02-RED-TRACE.md` |
| `cae1c5e2` | C — `vf-cockpit-arbres.mjs` : `GIT_SUR`, `brancheBase`, `retard`, `nettoie` |
| `12cd1b6e` | `arbresGit` ; `who.mjs` n'analyse plus la liste des worktrees (SOBR-01) |
| `3be2d265` | `phaseActive` (P68-PL-04) ; correction du harnais R4 de la suite |

Ordre tests, trace, code tenu (OK-ORDRE).

## Écarts au plan

1. Harnais R4 corrigé après le commit de tests : bash 3.2 mal-analyse les guillemets imbriqués dans `$( )` (JSON éclaté par brace expansion, sortie `illisible`). Aucune assertion changée ; le rouge tracé reste vrai (module absent).
2. Existence d'une référence testée par `show-ref --verify` (sortie non vide) au lieu de `--quiet` + code retour : `sh()` du socle rend la sortie, pas le code.
3. Deux ajouts de sûreté dans la suite : R5.1 refuse le vert à vide (l'emballage git doit avoir vu au moins 5 appels), R5.3 exige `core.fsmonitor=false` sur chaque appel journalisé.
4. `arbresGit` rend les chaînes brutes (le chemin sert à comparer des cwd) ; `nettoie` est appliquée par l'émetteur (68-03), R6.4 le consigne.
5. Deux phases de même numéro dans deux compartiments : la première de la feuille de route gagne pour la règle `phase-<n>` (précision, non tranchée par le plan).
6. Contre-épreuve par mutation (copie hors dépôt) : branche ignorée par `phaseActive` -> R4.1, R4.6 rouges ; `fetchAgeS` forcé à 0 -> R2.2, R2.3 rouges.

## Non-régression

`test-cockpit-who.sh` 87/0, `retard` 38/0, `vendor`, `reseau`, et toutes les `test-cockpit-*.sh` hors `signal*` et `vie` : les 22 suites rejouées sortent rc=0. `check-gate-touche.sh` : RIEN-A-JUGER ; `check-machine-paths.sh` : vert.
