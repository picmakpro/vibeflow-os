---
phase: quick-261003-ps1
plan: 01
quick_id: 261003-ps1
workstream: gouvernance
subsystem: planning-core (socle des empreintes, 46-01 / 46-03)
status: complete
tags: [empreintes, bloc-partage, point-fixe, budget-commun, openat, mutants]
requires: [46-01, 46-03]
provides:
  - "chaîne unique entrees_du_plan -> livrables_presents -> empreinte_livrables dans les trois scripts"
  - "refus 64 « dossier de l'unité » à la pose, R4 ecrit-contient-unite"
  - "budget commun par PLAN.md, lecture openat/O_NOFOLLOW/O_NONBLOCK"
affects: [46-05 (G3/G4 appelleront entrees_du_plan), 46-07 (D1, limite (g))]
tech-stack:
  added: []
  patterns: ["mandataire de os injecté dans l'espace de noms d'un bloc chargé (ordre provoqué, compteur, espion)"]
key-files:
  modified:
    - plugin/planning-core/scripts/poser-verdict.sh
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/recalc-planning.sh
    - plugin/planning-core/scripts/tests/test-cloture-empreintes.sh
    - plugin/planning-core/scripts/tests/test-recalc-planning.sh
    - plugin/planning-core/references/modele-cycles.md
decisions:
  - "Point fixe : une entrée ecrit: qui est ou contient le dossier de l'unité est refusée à la pose (64) — décision du manager (vf-dev-manager, mandat de correction ciblée du 2026-10-03, revue anticipée du socle), renversable"
  - "Limite (g) écrite au libellé MESURÉ : un dossier à la place de VERDICT.md fait échouer l'écriture (code 1), il ne remet pas le compteur à 1 avec succès"
plan_head_before: 74ba6378148e2e747b1d5c2501ac31eab0a7a155
estimate:
  tokens: 210000
  tasks: 3
actuals:
  tokens: 30243   # chars/4 sur le diff complet 74ba6378..45139c7f (lignes ajoutées seules : 18219)
  tasks: 3
  commits: 4      # git rev-list --count 74ba6378..HEAD, commit de ce SUMMARY compris
metrics:
  completed: 2026-10-03
---

# Quick 261003-ps1 Plan 01 : correction ciblée du socle des empreintes (F1-F6, F9) Summary

Le bloc partagé de S/bloc.py est posé à l'identique dans les trois scripts (vérifié octet pour octet par `cmp -s` contre
S/essai/). Il porte une chaîne unique `entrees_du_plan` -> `livrables_presents` (budget commun) -> `empreinte_livrables`,
avec une lecture par `openat` en `O_NOFOLLOW|O_NONBLOCK`. La pose refuse désormais en 64 une entrée qui est ou contient
le dossier de l'unité, et R4 rend `ecrit-contient-unite:<entrée>`. Chaque constat est prouvé par un cas, et les douze
mutants neufs sont tués par la garde visée. La référence est à jour, avec la limite (g) au libellé mesuré.

## Commits

| Tâche | Commit | Sujet |
|---|---|---|
| 1 | f6f38cf2 | fix(planning-core): chaîne unique des entrées ecrit:, budget commun et lecture sans lien du bloc d'empreintes (quick 261003-ps1, F1-F6, P46-D-12) |
| 2 | 111cb807 | test(planning-core): R-EMP-04 étendu, R-EMP-08 à R-EMP-12 et douze mutants ; R4 ecrit-contient-unite et borne cumulée (quick 261003-ps1) |
| 3 | 45139c7f | docs(planning-core): chaîne unique, budget commun, lecture sans lien, point fixe et limite (g) mesurée (quick 261003-ps1, F1-F6, F9) |
| 3 | (ce commit) | docs(quick-261003-ps1): PLAN et SUMMARY |

Chaque commit de code ou de suite porte un trailer `Gate-Touche:` par fichier touché.

## Suites (poste macOS chargé, au premier plan)

| Suite | OK | KO | Durée |
|---|---|---|---|
| test-cloture-empreintes.sh (après T1) | 23 | 0 | 20 s |
| test-recalc-planning.sh (après T1) | 398 | 0 | 107 s |
| test-cloture-empreintes.sh (final) | 40 | 0 | 59 s (DUREE 54 s) |
| test-recalc-planning.sh (final) | 405 | 0 | 257 s (278 s au passage de T2) |
| test-planning-gates.sh table,parseur,registre,jeton,g2,g5 | 20 | 0 | 15 s |
| test-planning-gates.sh g6,id,cang,g1,g7,role | 52 | 0 | 136 s |
| test-planning-gates.sh verdict,derog,env,obs_env,env_statique,accord | 17 | 0 | 31 s |
| test-planning-gates.sh banc,mutants,lota,reference | 372 | 0 | 611 s (voir écart 4) |
| test-planning-gates.sh, somme des quatre groupes | 461 | 0 | — |
| test-rejeu-gates.sh | 91 | 0 | 147 s |
| scripts/check-machine-paths.sh | rc 0 | — | 1920 fichiers |
| 45-CONTROLE-MARQUEUR.sh --base=247194c7 | MARQUEUR-BILAN commits=8 sans-marqueur=0 | — | — |

Aucun rouge, ni dans le périmètre ni hors périmètre. test-planning-gates.sh et test-rejeu-gates.sh n'ont pas été modifiés.

## Mutants neufs (douze, tous TUÉS, trace assertion/attendu/obtenu imprimée)

| Mutant | Script | Contrôle | Mot clé trouvé dans le rouge |
|---|---|---|---|
| MUT-EMP-ENTREES-DEQUOTE | recalc-planning.sh | R-EMP-04 | « dequote » (arbre ast + verdicts de entrees_du_plan sur les jeux quotés) |
| MUT-EMP-NOFOLLOW-AST | planning-hook.sh | R-EMP-04 | « SANS_SUIVI_DE_LIEN » |
| MUT-EMP-CHAINE-AST | recalc-planning.sh | R-EMP-04 | « entrees_du_plan » |
| MUT-UNITE-REFUS | poser-verdict.sh | R-EMP-08 | « dossier de l'unité » (poses en 0, tentative et dérogation consommées) |
| MUT-BUDGET-COMMUN | poser-verdict.sh | R-EMP-09 | « budget commun » (6+6 -> deux present ; p4 : 3697 entrées énumérées > 2500) |
| MUT-NOM-SAIN-CONTROLE | poser-verdict.sh | R-EMP-10 | « nom sain » |
| MUT-NOM-SAIN-UTF8 | poser-verdict.sh | R-EMP-10 | « nom sain » (appel direct sur `a\udcffb`, tué aussi sur macOS) |
| MUT-OCTETS-LUS | poser-verdict.sh | R-EMP-03 | « octets lus » |
| MUT-TRI | poser-verdict.sh | R-EMP-11 | « ordre » (les trois ordres provoqués divergent) |
| MUT-LIEN-INTERMEDIAIRE | poser-verdict.sh | R-EMP-12 | « lien » (lnk/f lu ; espion : sans O_NOFOLLOW) |
| MUT-NONBLOCK | poser-verdict.sh | R-EMP-12 | « O_NONBLOCK » (FIFO : ouverture bloquée, alarme de 5 s) |
| MUT-DIRFD | poser-verdict.sh | R-EMP-12 | « lien » (lnk/f lu ; espion : ouverture par chemin) |

Les mutants existants restent tués : EMP-VIDE, EMP-LIEN, EMP-BORNE, EMP-EXCLUS, EMP-AST, VERDICT-HASH-LIVRABLES, PLAF,
PLAF-CONSO, PLAF-ORDRE et JUGE-FORME dans la suite de clôture, et MUT-LIVRABLES et MUT-R4-VIDE (motifs portés sur la
nouvelle ligne R4) dans la suite du recalcul.

## Lignes « ~ non exercé »

- `  ~ R-EMP-10b non exercé (système de fichiers qui refuse les noms non UTF-8)` : APFS refuse la création de `\xff.txt`
  (OSError). Le cas s'exerce sur la CI Linux. La garde reste tuée sur macOS par l'appel direct `_nom_sain("a\udcffb")`.
- Sur ce poste, aucune autre ligne « ~ » : les noms à tabulation et à saut de ligne ont été créés, et le FIFO a été exercé.

## Sonde de la limite (g) (S/ag-sonde-limite-g.py, labs jetables dans S/ag-limite-g)

| Geste après la tentative 2 | Tentative essayée -> code | Tentative acceptée |
|---|---|---|
| VERDICT.md supprimé | 3 -> 64 ; 1 -> 0 | 1 |
| remplacé par un lien (vers un fichier `tentative: 9`) | 3 -> 64 ; 10 -> 64 ; 1 -> 0 (lien remplacé, cible intacte) | 1 |
| remplacé par un dossier | 3 -> 64 ; 1 -> **1** (IsADirectoryError, aucun verdict, le dossier reste) | aucune tant que le dossier reste |
| remplacé par un FIFO | 3 -> 64 ; 1 -> 0 | 1 |
| `tentative:` éditée à 0 | 3 -> 64 ; 2 -> 64 ; 1 -> 0 | 1 |
| `tentative:` éditée à 1 (au lieu de 3) | 4 -> 64 ; 3 -> 64 ; 2 -> 0 | 2 |

Libellé retenu, dans la référence et dans l'en-tête : « supprimer `VERDICT.md`, ou le remplacer par un lien ou un FIFO,
remet le compteur à 1 (tentative 1 acceptée, code 0 ; le lien est remplacé, jamais suivi) ; le remplacer par un dossier
remet le contrôle à 1 mais l'écriture échoue (code 1, aucun verdict posé tant que le dossier reste) ; y éditer
`tentative:` à une valeur plus basse remet le compteur à cette valeur + 1 (à `0`, la tentative 1 est acceptée). Les
écritures par Bash restent ouvertes ; D1 (plan 46-07) en trace la disparition. » Ce libellé corrige celui de
CONCEPTION §5, qui rangeait le dossier avec les objets qui remettent le compteur à 1 avec succès.

## Écarts à CONCEPTION.md et au plan

1. **[Prémisse] Rouge sur l'ancien code limité à F2, F3, F6 et R-EMP-04.** J'ai rejoué les sections emp et ast de la
   nouvelle suite contre les scripts de 63533989 (S/ag-sonde-ancien.py). R-EMP-08 est rouge (poses en 0), et R-EMP-09,
   R-EMP-12 et R-EMP-04 aussi (l'API n'existait pas). R-EMP-10 et R-EMP-11, en revanche, sont VERTS sur l'ancien code,
   et le cas « octets lus » y passerait aussi. Raison : `_nom_sain`, le tri final et le contrôle `budget[2]` existaient
   déjà en 46-01. Les constats F4 et F5 de la revue portaient sur des gardes non tuées (sonde mut2), pas sur un
   comportement faux. La preuve de F4 et F5 est donc la mort des mutants NOM-SAIN-*, OCTETS-LUS et TRI, et non un rouge
   sur l'ancien code.
2. **[Conception] Le contrôle (c) de R-EMP-12 exige un dir_fd selon la capacité du système, pas selon le bloc.** La
   capacité est calculée par la suite elle-même (`os.open in os.supports_dir_fd and hasattr(os, "O_DIRECTORY")`), et
   non lue dans `AVEC_DESCRIPTEURS` du bloc chargé. Sans cela, le mutant DIRFD se couvrirait lui-même. Il reste tué par
   le cas (a) et aussi par l'espion.
3. **[Banc] Aucun fichier de fixtures touché.** Les cas R-UNITE-01 et R-R4BORNE-01 se construisent dans la suite, sur
   des copies matérialisées de `livrable-vide-jumeau`.
4. **[Durée] Le groupe `banc,mutants,lota,reference` de test-planning-gates.sh a duré 611 s**, au-delà du timeout de
   600 s de l'outil. Le harnais l'a alors basculé en arrière-plan de lui-même ; je ne l'ai jamais lancé ainsi. Il s'est
   terminé avec le code 0 (372 OK, 0 KO), et je n'ai rendu la main qu'après. Je ne l'ai pas rescindé, puisque le
   résultat complet était acquis. Machine chargée : c'est un dépassement de temps, pas un défaut fonctionnel.
5. Aucune modification de bloc.py : les trois copies restent égales à S/essai/ pour le bloc. Le cas « ancêtre .planning »
   de R-EMP-04 utilise une liste à deux entrées (livrables/rapport.md puis .planning), pour éprouver l'ordre des refus.

## Point signalé au manager (finding, sévérité basse, action ask-user)

Le cache du recalcul garde `cache_schema_version` 2. Une entrée de cache écrite par le moteur de 46-03, pour une unité
dont `ecrit:` couvre son dossier, peut être reprise avec l'ancien état tant que la signature et les livrables ne
changent pas. La montée de schéma n'est pas faite : elle sort de CONCEPTION.md. Une fois une telle unité recalculée
par le nouveau moteur, son entrée surveille `ecrit: []`.

## Known Stubs

Aucun.

## Threat Flags

Aucune surface nouvelle hors du `<threat_model>` du plan : T-ps1-01 à T-ps1-07 sont mitigées et prouvées par les cas et
mutants ci-dessus, et T-ps1-08, T-ps1-09 et T-ps1-11 sont déclarées dans modele-cycles.md.

## Self-Check: PASSED

Les six fichiers modifiés existent, et les commits f6f38cf2, 111cb807 et 45139c7f sont présents sur
worktree-agent-a3e7355f4619b5828.
