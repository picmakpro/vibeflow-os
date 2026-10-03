---
phase: 45-moteur-hook-central-par-r-le-et-gates-d-criture
plan: 01
subsystem: planning-core (hook central PreToolUse, gates d'écriture)
tags: [hook, fail-closed, pretooluse, gates, g2, armement, shell-posix, python-embarque, mutation-testing]

requires:
  - phase: 44-moteur-de-planning-metier
    provides: adhésion cycles-v1 (verifier_adhesion), parseur de frontmatter (lire_frontmatter), banc texte et mutants make_recalc_mutant
provides:
  - "planning-hook.sh : lanceur bash + cœur Python (racine du lab, adhésion, table d'armement, G2)"
  - "hooks.json : UNE entrée PreToolUse de forme shell, commande enregistrée fail-closed (verbatim de la recherche)"
  - "test-planning-hook-registered.sh : rejeu de la commande enregistrée, corpus de 60 cas, six modes, quatre shells, 17 mutants"
  - "test-planning-gates.sh + fixtures/gates-banc.txt : table d'armement, parseur ast-identique, G2, banc, 9 mutants"
  - "45-CONTROLE-MARQUEUR.sh : contrôle du marqueur Gate-Touche de la phase (artefact de phase, non livré)"
  - "docs/HOOKS-CONTRAT-SORTIE.md : inventaire 29 -> 30 entrées"
affects: [45-03, 45-04, 45-05, 45-06, 45-07, 45-08, 45-09, 45-10]

plan_head_before: 0c5e6315524dc4a15f2a0931f034f71021b7582c
estimate:
  tokens: 160000
  tasks: 3
actuals:
  tokens: 33828    # chars/4 sur les lignes ajoutées du diff réalisé (git diff -U0 base..HEAD), hors ce SUMMARY
  tasks: 3
  commits: 7       # MESURÉ : git rev-list --count 0c5e631..HEAD avant le commit de ce SUMMARY

tech-stack:
  added: []
  patterns:
    - "commande enregistrée fail-closed en shell POSIX pur (grep -a -o, case glob, décodage par segments, cd -P) qui décide « lab adhérent ou non » sans python3"
    - "cœur Python en deux temps : erreur avant l'adhésion = code 3 sans sortie (la couche shell tranche), après = deny JSON code 0"
    - "table d'armement = constantes du code livré, une ligne chacune ; mutants à motif unique et quatre conditions"
    - "avertissement G2 par hookSpecificOutput.additionalContext (jamais permissionDecision)"

key-files:
  created:
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/tests/test-planning-hook-registered.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/scripts/tests/fixtures/gates-banc.txt
    - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-CONTROLE-MARQUEUR.sh
  modified:
    - plugin/planning-core/hooks/hooks.json
    - docs/HOOKS-CONTRAT-SORTIE.md
    - README.md
    - README.fr.md

key-decisions:
  - "[POINT DE DÉCISION F2] forme shell retenue (P45-D-15, contrainte 7 du mandat) : la forme exec {{VF_BASH}} part dans settings.local.json et n'a pas de shell pour le test de présence"
  - "[POINT DE DÉCISION PY3] la présence de l'interpréteur est testée par le lanceur (cascade python3 puis python, ADR-054), tout code non nul est repris par la commande"
  - "[POINT DE DÉCISION G2-REF] référentiel = union des ecrit: des plans ouverts, tout écrivain (fil principal compris), Bash = jeton de la commande qui nomme un chemin du lab ; précision : un jeton n'est retenu que s'il ressemble à un chemin (contient / ou . ou nomme une entrée existante) et ne porte aucun métacaractère de motif ou de charge utile"
  - "clé en double dans le payload : première occurrence gagnante côté Python aussi (object_pairs_hook), pour que les deux couches décident pareil"
  - "limites déclarées (a) à (i) reportées telles quelles ; la limite (i) (copie du script exécutée sous $CLAUDE_PROJECT_DIR) n'est pas testée par R-ENV-01 (P45-D-21b)"

requirements-completed: [GATE-01, GATE-02, GATE-03, GATE-08, GATE-10, GATE-15]

duration: 34min
completed: 2026-09-30
status: complete
---

# Phase 45 Plan 01: Hook central — commande enregistrée fail-closed, cœur Python, table d'armement et G2 Summary

**Une seule entrée PreToolUse, fail-closed dans un lab adhérent cycles-v1 (deny statique quand le script ou python3 manque ou plante, Bash ouvert) et muette partout ailleurs (ce dépôt compris), un cœur Python à deux phases qui ne sort jamais en code 2, une table d'armement en constantes du code livré (tout à observe) et G2 qui avertit par additionalContext sans jamais refuser — prouvés par 82 cas verts et 26 mutants tués.**

## Performance

- **Duration:** ~34 min (10:44:04Z -> 11:17:56Z, horloge de la session, rejeux des suites compris)
- **Tasks:** 3/3 (1 traceur, 2 auto tdd)
- **Files modified:** 9 (5 créés, 4 modifiés)
- **Commits de tâche:** 7 (mesuré depuis `plan_head_before`)

## Accomplishments

- **Commande enregistrée fail-closed** (texte verbatim de `45-RESEARCH.md`, généré par `json.dumps`, relu par `json.load`) : posée par `merge-hooks.sh` dans `settings.json` (jamais `settings.local.json`), idempotente, retirée sans résidu ; la commande POSÉE est rejouée dans R-CMD-02.
- **Lanceur + cœur Python** : `mktemp` 0600 + trap, cascade python3/python, `-I -S`, heredoc quoté unique ; phase A (payload, cible, racine, adhésion) sort en code 3 sans rien imprimer sur toute exception, phase B tout entière sous `try/except BaseException` -> deny `erreur interne ... (P45-D-08)`, code 0 ; aucun chemin en code 2.
- **Zéro régression dev prouvée par une mesure qui peut rougir** : voir la preuve brute ci-dessous ; la mutation « ignorer l'adhésion » (MUT-PY-ADHESION) rend R-G2-07 rouge, MUT-EXT-7 (TIGHT relâché) et MUT-EXT-5 (le cwd prime) rendent le corpus rouge.
- **Table d'armement dans le code livré** (`ARMEMENT_G6/G5/G1/G7/ROLE` = `observe`, `G2_MODE` = `avertit`, `ORDRE_ETAPES`), `armement_valide`, refus (deny) si la table livrée viole l'ordre ; aucune variable d'environnement ni fichier du lab n'y touche (R-ENV-01, 30 rejeux sous 5 environnements, état livré et copie armée).
- **Parseur de frontmatter ast-identique** à `lire_frontmatter` de `recalc-planning.sh` (avec `dequote`, `CLE_RE`, `_lire_liste_indentee`) ; contrôle croisé par `ast.dump`, rouge à la moindre divergence (MUT-PARSEUR).
- **G2** : avertit (`additionalContext` qui nomme G2, P45-D-10 et Bash) sur écriture hors `ecrit:` de tout plan ouvert (union), Write/Edit/NotebookEdit et Bash ; plan clos ou dérogé ne couvre rien ; frontmatter illisible = plan ignoré ; silence hors lab adhérent ; 400 plans ouverts tranchés en 0,06 s.
- **Suites** : `test-planning-hook-registered.sh` (35 OK, corpus de 60 cas, six modes A-F sous /bin/sh, extraction sous sh/dash/bash/zsh contre un oracle indépendant, R-PERF 5 Mo, R-DEPOT 54 rejeux, 17 mutants) et `test-planning-gates.sh` (47 OK, 9 mutants). Rejouées aussi avec `/bin/dash` comme `/bin/sh` (la CI Linux) : mêmes verdicts.

## Task Commits

1. **Tâche 1 (traceur) : commande enregistrée, lanceur, cœur, R-CMD-01 à 08** — `d54b4b5` (feat) ; `6c484e2` (docs, compteur de suites 93 -> 94) ; `2250e22` (docs, `45-CONTROLE-MARQUEUR.sh`)
2. **Tâche 2 : couche shell sur corpus adverse, six modes, shells, dépôt, 5 Mo, 17 mutants** — `48bd63a` (test)
3. **Tâche 3 : table d'armement, parseur ast-identique, G2** — `2194092` (feat) ; `2ba0026` (test, suite + banc) ; `1d63aa1` (docs, compteur 94 -> 95)

**Tracer feedback gate** (avant Tâche 2) : `<verify>` de la Tâche 1 rejoué de bout en bout après le commit `d54b4b5` (R-CMD-01 à 08 verts, T12 vert à 30, check-version-sync vert, contrôle du marqueur `sans-marqueur=0`) — « Tracer verified end-to-end — expanding ».

**Plan metadata:** commit de ce SUMMARY (docs). Aucune écriture de `STATE.md`, `ROADMAP.md` ni `REQUIREMENTS.md` (voir Étapes sautées).

## Preuve de zéro régression dev (truth de 45-01)

Commande exacte, lancée depuis la racine de ce dépôt (lab dev) : rejeu, sous `/bin/sh -c`, de la commande enregistrée LUE DANS `plugin/planning-core/hooks/hooks.json` (jeton `{{VF_SCRIPTS}}` substitué par le dossier des scripts), stdin = le payload du harnais (JSON compact, ordre des clés du harnais), cwd et cibles dans ce dépôt.

```
python3 preuve-dev.py     # script jetable du scratchpad de la session ; extrait :
#   cmd = json.load(open("plugin/planning-core/hooks/hooks.json"))["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
#   cmd = cmd.replace("{{VF_SCRIPTS}}", "'<dépôt>/plugin/planning-core/scripts'")
#   subprocess.run(["/bin/sh", "-c", cmd], input=<payload>, stdout=PIPE, stderr=PIPE, cwd=<dépôt>)
```

Sortie brute :

```
Write        rc=0 stdout=0 octet(s) stderr=0 octet(s)
Edit         rc=0 stdout=0 octet(s) stderr=0 octet(s)
NotebookEdit rc=0 stdout=0 octet(s) stderr=0 octet(s)
Bash         rc=0 stdout=0 octet(s) stderr=0 octet(s)
Agent        rc=0 stdout=0 octet(s) stderr=0 octet(s)
Task         rc=0 stdout=0 octet(s) stderr=0 octet(s)
RESULTAT mauvais=0
```

Version de suite (54 rejeux : six outils x trois cibles `.planning/STATE.md`, `README.md`, `plugin/planning-core/VERSION` x modes A script réel, C script absent, D python absent) :

```
$ bash plugin/planning-core/scripts/tests/test-planning-hook-registered.sh 2>&1 | awk '/✓ R-DEPOT|✓ R-CMD-03/'
  ✓ R-CMD-03 lab dev, script présent : stdout d'octet vide et code 0 pour Write, Edit, NotebookEdit, Bash, Agent, Task
  ✓ R-DEPOT ce dépôt (lab dev) : 54 rejeux (six outils, trois cibles, modes A, C, D) : stdout 0 octet, code 0
```

Mutations qui rendent cette preuve rouge (trace attendu/obtenu imprimée par la suite) : `MUT-PY-ADHESION` (R-G2-07, la « mutation ignorer l'adhésion » : un lab dev reçoit un avertissement), `MUT-EXT-7` (TIGHT relâché : un dev qui mentionne cycles-v1 est refusé), `MUT-EXT-5` (le cwd prime : un dev voisin est refusé), `MUT-EXT-3` (le plus proche ne gagne plus).

## Files Created/Modified

- `plugin/planning-core/scripts/planning-hook.sh` — lanceur bash + cœur Python embarqué (une seule occurrence du heredoc `PY_PLANNING_HOOK_EOF`)
- `plugin/planning-core/hooks/hooks.json` — entrée `PreToolUse` unique (matcher `Write|Edit|NotebookEdit|Bash|Agent|Task`, `timeout: 20`, forme shell) ; `description` étendue ; trois événements préexistants inchangés (comparés après `json.load`)
- `plugin/planning-core/scripts/tests/test-planning-hook-registered.sh` — 35 assertions
- `plugin/planning-core/scripts/tests/test-planning-gates.sh` — 47 assertions
- `plugin/planning-core/scripts/tests/fixtures/gates-banc.txt` — banc texte (labs `g2-adherent`, `g2-dev`, directive `@@ ecriture`)
- `docs/HOOKS-CONTRAT-SORTIE.md` — 29 -> 30 entrées (titre, assertion `n==30`, ligne n°30, §5)
- `README.md`, `README.fr.md` — « N suites » 93 -> 95
- `.planning/workstreams/gouvernance/phases/VFDO-45-.../45-CONTROLE-MARQUEUR.sh` — contrôle du marqueur, `--autotest` `cas=7 ko=0`

## Decisions Made

Voir `key-decisions`. Aucun arbitrage humain nouveau invoqué : toutes les décisions appliquées sont celles du plan et de `45-CONTEXT.md` (P45-D-01, 01a, 03, 03a, 04, 06, 06a, 06b, 08, 10, 12, 12a, 15, 16, 19, 21b).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] G2 sur Bash : faux positifs sur des jetons qui ne sont pas des chemins**
- **Found during:** Tâche 2 (rejeu du corpus E15 : Bash dont la commande cite un objet `{"file_path": ...}`, cwd dans le lab adhérent)
- **Issue:** la lecture littérale de G2-REF (« tout jeton qui nomme un chemin sous la racine du lab ») avertissait sur un jeton JSON, sur `echo`, `ls`... : bruit à chaque commande Bash d'un lab adhérent.
- **Fix:** un jeton n'est retenu que s'il ressemble à un chemin (contient `/` ou `.`, ou nomme une entrée existante), ne commence ni par `-` ni par `~`, et ne porte aucun métacaractère de motif ou de charge utile ; préfixe de redirection retiré. Reste une détection, jamais une promesse (P45-D-10).
- **Files modified:** plugin/planning-core/scripts/planning-hook.sh
- **Commit:** `2194092`

### Écarts de mise en oeuvre (sans changement de contrat)

**2. hooks.json édité par insertion de texte, pas par réécriture `json.dump` complète** : la commande est encodée par `json.dumps` (jamais éditée à la main), relue par `json.load` et comparée au texte de travail ; les trois événements préexistants comparés à leur structure de base ; le diff de `hooks.json` reste minimal (14 lignes) au lieu de reformater tout le fichier.

**3. Aides des suites en Python embarqué** (`PY_AIDES_REG_EOF`, `PY_AIDES_GATES_EOF`) plutôt qu'en bash pur : `make_hook_mutant` et `make_cmd_mutant` sont des fonctions Python de même contrat que `make_recalc_mutant` (motif fixe à occurrence unique, texte distinct, `bash -n`/`sh -n`, compilation du corps extrait), même format de sortie (`✓ MUT-... TUÉ — ... attendu (original) ... obtenu (mutant)`, `NON TUÉ`), portables GNU/BSD.

**4. Témoins des mutants de la couche shell** : pour `MUT-CMD-3` (test de présence retiré) tout cas du mode C est affecté (bruit stderr de `bash` sur un script absent) : discriminant = stderr en mode C, témoin rejoué en mode A ; `MUT-CMD-2` (code de sortie ignoré) rejoué en mode E avec témoin `E27` (Agent sous lab dev) dans le même mode. Le substitut du mode E n'imprime rien sur stdout (sinon le mutant rendrait un document partiel) ; celui du mode F imprime un objet partiel qui ne doit jamais être relayé.

**5. R-CMD-01 tolère les ajouts aux événements préexistants** : les entrées de base doivent être retrouvées, dans l'ordre, inaltérées (sous-suite) ; 45-03 ajoutera l'entrée SessionStart du canary sans devoir toucher cette suite.

**6. Compteur de suites de départ 93, pas 92** (le plan cite 92, mesuré le 2026-09-29) : `main` avait avancé ; recomptage par `find` comme prescrit -> 94 puis 95.

**7. `docs/HOOKS-CONTRAT-SORTIE.md` au-delà de la lettre du plan** : les décomptes dérivés (« 6 entrées bloquantes sur les 29 » -> « 7 sur les 30 », « 20 entrées gouvernance » -> « 21 », note de pied) suivent l'entrée n°30 pour ne pas laisser un chiffre faux dans le même document.

**8. Registre du HEAD de départ hors du dossier git** : la garde d'isolation du poste refuse d'écrire sous `.git/worktrees/...` ; le HEAD de départ (`0c5e631`) est consigné dans le scratchpad de la session, `commits:` est mesuré par `git rev-list --count 0c5e631..HEAD`.

**9. `HOME` fictif** : le poste refuse le préfixe `env HOME=... bash suite` ; les deux suites donnent à leurs enfants un `HOME` jetable (`$WORK/home`) et le rejeu groupé des suites a été lancé par un script du scratchpad qui exporte `HOME` vers le dossier jetable `home-01`. Aucune des deux suites nouvelles ne lit `HOME` pour décider quoi que ce soit.

## Authentication Gates

Aucune.

## Suites rejouées (HOME jetable, découverte complète NON lancée)

| Suite | Résultat |
|---|---|
| planning-core/test-planning-hook-registered.sh | 35 OK · 0 KO (~16-40 s selon la charge ; rejouée aussi sous `/bin/dash` : 35/0) |
| planning-core/test-planning-gates.sh | 47 OK · 0 KO (~12 s ; rejouée aussi sous `/bin/dash` : 47/0) |
| planning-core/test-check-planning-state.sh | 19 ok · 0 ko |
| planning-core/test-detect-gsd-engine.sh | 26 ok · 0 ko |
| planning-core/test-detect-planning-debt.sh | 10 passés · 0 échoués |
| planning-core/test-planning-context-hardening.sh | 38 passés · 0 échoués |
| planning-core/test-planning-core.sh | 14 passés · 0 échoués |
| planning-core/test-planning-hooks.sh | 42 PASS · 0 FAIL |
| planning-core/test-workstream-policy.sh | 21 ok · 0 ko · 1 skip |
| planning-core/test-workstream-symlink-escape.sh | 10 ok · 0 ko |
| planning-core/test-recalc-planning.sh | 313 OK · 0 KO (63 s ; fichier non touché par ce plan, rejeu de non-régression) |
| _internal/test-merge-hooks.sh | 39 OK · 0 KO |
| _internal/test-manifest.sh | 62 OK · 0 KO |
| _internal/test-vibeflow-update.sh | 67 OK · **18 KO** · 3 skip (157 s) — les 18 KO (T37, T48 à T53 : codex, `fidelity-coexistence`, `use_worktrees`, `.planning/config.json`) sont IDENTIQUES ligne à ligne (`comm`) au relevé de base de la mission de planification (poste, avant tout changement de ce plan) : pré-existants, hors périmètre, non corrigés (voir Deferred Issues) |
| dev-orchestrator/test-check-hook-paths.sh | 17 OK · 0 KO (T12 : 30 entrées, doc et parc identiques) |
| scripts/tests/test-hook-exit-parc.sh | 42 OK · 0 KO |
| scripts/check-version-sync.sh | ✓ sources synchronisées |
| scripts/check-machine-paths.sh | ✓ aucun chemin absolu de machine |
| conductor/check-planning-consumers-registered.sh | ✓ tous recensés (recensement inchangé) |
| 45-CONTROLE-MARQUEUR.sh `--autotest` | `AUTOTEST cas=7 ko=0` ; `--base=fd49137` sur les deux jeux de fichiers du plan : `sans-marqueur=0` |

## Limites déclarées portées par ce plan (à reprendre en 45-10 et 45-03)

Limites (a) à (h) de `45-RESEARCH.md` R1 et limite (i) (P45-D-21b) : couvertes par des cas déclarés `tight`/`none` du corpus (E19 pour (a), A03/A04 pour (b), A13 pour (c), E09b pour (d)) ; (g) Bash reste ouvert en mode dégradé (P45-D-06b) : R-CMD-05/06, MUT-CMD-7 ; (i) : non testée par R-ENV-01 (`CLAUDE_PROJECT_DIR` vers une copie identique seulement).

## Known Stubs

Aucun. `evaluer_gates` ne branche que G2 dans ce plan : G6, G5, G1, G7 et le rôle arrivent en observation dans 45-04 à 45-09 (P45-D-03) ; ce n'est pas un stub, c'est le périmètre du plan.

## Threat Flags

Aucune surface nouvelle hors du `<threat_model>` du plan (T-45-01 à T-45-07 mitigés : deny statique ASCII, adhésion TIGHT et précédence du chemin, une passe grep linéaire, armement en constantes, fichier de transport 0600 avec trap).

## Étapes du workflow sautées (consigne du dispatcher, ADR-063)

Aucune commande `gsd-tools state <verbe>` ni écriture ROADMAP n'a été lancée : `STATE.md` et `ROADMAP.md` du compartiment `gouvernance` ne sont pas touchés. `requirements mark-complete` non lancé non plus (le dispatcher centralise, et 45-02 tourne en parallèle) : les exigences GATE-01, 02, 03, 08, 10, 15 sont couvertes par ce plan, à cocher par l'orchestrateur.

## Deferred Issues

- `plugin/_internal/tests/test-vibeflow-update.sh` : 18 KO pré-existants sur ce poste (T37, T48 à T53), identiques au relevé de base ; sans lien avec le hook central (codex, `fidelity-coexistence`, `use_worktrees`). Rapportés, non corrigés (règle de périmètre).
- Le rejeu de non-régression n'a lancé aucune découverte complète des 93 suites (consigne) : seules les suites nommées par le plan, les 9 suites de `planning-core/scripts/tests/` (hors les deux nouvelles), et celles de `_internal/tests/` que `hooks.json` ou les README touchent.

## Self-Check: PASSED

Vérifié avec un script jetable : les 7 fichiers créés ou modifiés existent (`FOUND`), les 7 commits de tâche existent (`FOUND`).
