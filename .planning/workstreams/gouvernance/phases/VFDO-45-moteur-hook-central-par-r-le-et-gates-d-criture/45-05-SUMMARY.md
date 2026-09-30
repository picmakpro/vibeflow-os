---
phase: 45-moteur-hook-central-par-r-le-et-gates-d-criture
plan: 05
subsystem: planning-core (G6 fichiers générés, identité des fichiers protégés, canary de l'étape 1, rejeu de l'étape 1)
tags: [hook, g6, g5, identite, samefile, canary, observation, rejeu, f6, f7b, mutation-testing, escalade]

requires:
  - phase: 45-03
    provides: check-gates-alive.sh (CANARIS, attendu dérivé de la table), rejeu-gates.sh (registre CONSTRUCTEURS, fusion à trois rangs), rejeu-reel.sh
  - phase: 45-04
    provides: entonnoir decider/observer, evaluer_g5, dérogations, journal d'observation
provides:
  - "planning-hook.sh : evaluer_g6, fichier_protege (identité Pattern 5), contrôle de l'adhésion de config.json (F6), cache protégé (F7b), G5 par lien dur"
  - "check-gates-alive.sh : cas G6-principal, G6-plugin, G5-verdict ; type d'attendu « observation » (ligne gate=<G> exigée au journal jetable du rejeu)"
  - "rejeu-gates.sh : constructeurs G6 et G5, charge d'un Edit dans le tuple de constructeur"
  - "test-planning-gates.sh : R-G6-01..05, R-CANG-01..03, R-ID-01..06, COUVERTURE G6, COMPTE G5 et G6, 8 nouveaux mutants ; test-rejeu-gates.sh : R-REJEU-G6G5, MUT-REJEU-G6-ENREGISTRE"
  - "45-REJEU-ETAPE-1.md : relevé de l'étape 1 — rejeu réel NON effectué (labs non au repos), ESCALADE-WILLY ETAPE-1"
affects: [45-06, 45-07, 45-08, 45-09, 45-10]

plan_head_before: d88d68532a0d59ac53379cc4878e5a72612630e8
estimate:
  tokens: 150000
  raw_tokens: 150000
  tasks: 3
  confidence: low
actuals:
  tokens: 11653    # chars/4 sur les lignes ajoutées du diff réalisé (git diff -U0 base..HEAD sous plugin/, 46613 caractères), hors ce SUMMARY et le relevé
  tasks: 3
  commits: 3       # MESURÉ : git rev-list --count d88d685..HEAD avant le commit de ce SUMMARY

tech-stack:
  added: []
  patterns:
    - "identité avant chaîne : cible existante par os.path.samefile (lien dur, variante de casse du disque, alias du dossier de planning), création par le dossier parent résolu et le nom en casefold, segment .. résolu par realpath"
    - "canary à deux attendus : observation (ligne gate=<G> au journal d'un XDG_CACHE_HOME jetable, sinon le gate est muet et non vivant) tant que le gate est en observe, deny-gate dès qu'il est armé, jamais le texte du fail-closed"
    - "constructeur de corpus qui prime sur la réécriture générique pour la même clé (outil, chemin, agent_type) ; une charge d'outil distincte donne une clé distincte (Edit de config.json)"
    - "une règle d'armement mécanique lue sur un relevé : deux comptes nuls ET empreinte d'arbre identique, sinon rien ne s'arme"

key-files:
  created:
    - .planning/workstreams/gouvernance/phases/VFDO-45-moteur-hook-central-par-r-le-et-gates-d-criture/45-REJEU-ETAPE-1.md
  modified:
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/check-gates-alive.sh
    - plugin/planning-core/scripts/rejeu-gates.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/scripts/tests/test-rejeu-gates.sh
    - plugin/planning-core/scripts/tests/fixtures/gates-banc.txt
    - plugin/_internal/tests/test-planning-hook-installed.sh

key-decisions:
  - "F6 = f6-oui, F7b = f7b-oui, rejeu réel autorisé (Willy, AskUserQuestion session principale, 2026-09-30) : relayés par le dispatcher au checkpoint de la Tâche 2, cités dans les commits et dans l'en-tête du relevé, rien tranché ni redemandé"
  - "Armement : NON. La précondition de repos de la Tâche 3 n'est pas tenue (26 processus, dont deux sessions Claude Code, ont leur répertoire courant sous ~/BusinessFlow-Lab) ; le plan fixe alors : aucun rejeu réel, aucun armement, ESCALADE-WILLY ETAPE-1 motif « labs réels non au repos »"
  - "config.json (F6) est dans PROTEGES_G6 au genre `adhesion` : le seul contrôle est de contenu (le contenu qu'un Write ou qu'un Edit appliqué en mémoire produirait garde planning_version = cycles-v1) ; le hook ne lit config.json que pour l'adhésion et, sous F6, pour appliquer l'Edit"
  - "Sur un système sensible à la casse le refus par casefold d'une création reste actif (`.planning/state.md`, `.PLANNING/STATE.md` refusés) : excès théorique accepté par la recherche (Pattern 5), donc aucun jumeau « ne refuse pas à tort » pour la casse ; MUT-ID-CASEFOLD est tué sur tout système par une création en autre casse d'un nom absent"
  - "Le Edit de config.json qui perd l'adhésion est rejoué comme une clé Edit distincte de la réécriture Write identique : un attendu par clé, les deux lignes du relevé sont donc distinctes"

requirements-completed: [GATE-04, GATE-05, GATE-11, GATE-12, GATE-13, GATE-15]
requirements-note: "à cocher par l'orchestrateur (ADR-063) ; GATE-13 (mesure deux sens sur labs réels) et l'armement de GATE-04 et GATE-05 restent ouverts tant que le rejeu réel n'a pas eu lieu"

status: complete
---

# Phase 45 Plan 05: G6, identité des fichiers protégés, canary de l'étape 1, rejeu Summary

**G6 refuse, en observation, toute écriture par outil d'un fichier généré (état, index, clôture, journal de dérogation, cache) comme d'un `config.json` qui perdrait l'adhésion, par comparaison d'identités de fichiers ; le canary prouve G6 et G5 vivants ; le banc est nul dans les deux sens, mais le rejeu réel n'a pas pu avoir lieu (BusinessFlow sous session ouverte) : G6 et G5 restent en observation et l'étape 1 remonte à Willy.**

## Performance

- **Tâches :** 3/3 (Tâche 1 tracer, Tâche 2 point de décision relayé, Tâche 3 auto tdd) ; la Tâche 3 s'arrête à l'escalade prévue par son plan
- **Commits de tâche :** 3 (mesuré depuis `plan_head_before`) ; la Tâche 2 est une réponse relayée, sans commit
- **`test-planning-gates.sh` :** 104 OK (45-04) -> 136 OK (Tâche 1) -> **147 OK · 0 KO**, dont 8 nouveaux mutants tués (MUT-G6-RACINE, MUT-G6-NOMS, MUT-CANG-OBS, MUT-ID-SAMEFILE, MUT-ID-SAMEFILE-G5, MUT-ID-CASEFOLD, MUT-F6, MUT-F7B)
- **`test-rejeu-gates.sh` :** 36 -> **38 OK · 0 KO** (R-REJEU-G6G5, MUT-REJEU-G6-ENREGISTRE)

## Accomplishments

- **G6 (Tâche 1).** `evaluer_g6` dans l'entonnoir, en observation : une ligne `gate=G6` au journal d'observation, rien au modèle. Le motif d'un refus (quand il sera armé) nomme `recalc-planning.sh` (ou `deroger-gate.sh` pour le journal) : le Stop de la 44 (Pitfall 9) n'est pas contredit. Les `STATE.md` de `workstreams/` et `compartments/` ne sont pas visés.
- **Canary (Tâche 1).** Trois cas ajoutés à `CANARIS` : `G6-principal`, `G6-plugin` (agent `plugin-inconnu:agent-inconnu`), `G5-verdict` (agent inconnu). Attendu dérivé de la table : `observation` (ligne au journal jetable du rejeu) tant que le gate est en observe, `deny-gate` dès qu'il est armé ; un gate neutralisé fait signaler le canary (R-CANG-03), qu'il soit en observe ou armé.
- **Identité (Tâche 3).** `fichier_protege` : cible existante par `samefile` contre chaque protégé présent (lien dur, casse du disque, alias), création par le dossier parent résolu et le nom en casefold, `..` résolu ; G5 : un lien dur (`st_nlink > 1`) vers un VERDICT.md du dossier de planning est ce VERDICT.md, parcours borné et trié.
- **F6 et F7b (Tâche 3).** `config.json` : un Write dont le contenu ne garde pas `planning_version = cycles-v1`, un Edit appliqué en mémoire (replace_all respecté ; inapplicable = refus motivé), un NotebookEdit : refus de G6 ; les autres clés restent libres. `.recalc-cache.json` : protégé.
- **Rejeu (Tâche 3).** Constructeurs `G6` (chaque nom protégé en doit-refuser, `config.json` réécrit à l'identique en doit-passer, le même Edit qui perd l'adhésion en doit-refuser) et `G5` (VERDICT.md à côté de chaque PLAN.md copié, et chaque VERDICT.md copié, en doit-refuser). Une ligne par clé ; les constructeurs livrés ne jouent pas dans les essais des autres gates (isolement par scénario).
- **Banc.** `COMPTE G5 faux-refus=0 faux-accept=0`, `COMPTE G6 faux-refus=0 faux-accept=0` (R-ID-06, banc complet sur copie armée) ; `COUVERTURE G6 : 11 doit-refuser, 6 doit-passer, 3 silence`.

## Task Commits

1. **Tâche 1 (tracer) :** `174027d` — G6 en observation et cas de canary de l'étape 1 (R-G6, R-CANG, banc, 3 mutants). Deux trailers Gate-Touche.
2. **Tâche 2 (checkpoint:decision) :** aucune modification ; F6 = f6-oui, F7b = f7b-oui, rejeu-oui (Willy, AskUserQuestion session principale, 2026-09-30), relayés par le dispatcher.
3. **Tâche 3 :** `186daa3` — identité des fichiers protégés et périmètre de G6 (F6, F7b, constructeurs du rejeu, R-ID, R-REJEU-G6G5, 6 mutants) ; `580153f` — relevé `45-REJEU-ETAPE-1.md` (rejeu réel non effectué, ESCALADE-WILLY ETAPE-1).

**Tracer feedback gate** (avant la Tâche 2) : `<verify>` de la Tâche 1 rejoué de bout en bout (suite des gates, canary posé) après le dernier changement du canary, vert : « Tracer verified end-to-end — expanding ».

## Relevé du rejeu de l'étape 1 et état d'armement

- **Lignes du relevé :** aucune ligne `REJEU-ETAPE-1`, aucune ligne `EMPREINTE-ARBRE-*` : **aucun rejeu réel n'a eu lieu**. Seule ligne d'escalade : `ESCALADE-WILLY ETAPE-1 labs réels non au repos`.
- **Motif (précondition de la Tâche 3) :** `lsof -d cwd` (lecture seule), lu trois fois, dernière à 2026-09-30T19:38Z : `~/jarvis-keystone` 0 processus ; `~/BusinessFlow-Lab` 26 processus (12 `node`, 5 `zsh`, 2 `uv`, 2 `python3.11`, 2 `Code Helper (Plugin)`, 1 `sleep`, 2 sessions Claude Code 2.1.284 et 2.1.283). Un rejeu sous session ouverte ne prouve pas l'absence d'écriture. Aucun des deux labs n'a été lu au-delà de l'existence de leur dossier de planning ; aucune commande git n'y a été lancée.
- **Armement livré :** `ARMEMENT_G6 = "observe"`, `ARMEMENT_G5 = "observe"`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` : `"observe"` ; `G2_MODE = "avertit"` ; `TABLE_ATTENDUE` de la suite inchangée. Règle P45-D-03b : banc nul (vrai), rejeu réel absent, donc rien ne s'arme.
- **Pour lever l'escalade** (dans le relevé) : fermer les sessions ouvertes sur `~/BusinessFlow-Lab`, puis `bash plugin/planning-core/scripts/rejeu-reel.sh --lab="$HOME/jarvis-keystone" --lab="$HOME/BusinessFlow-Lab" --etape=1 --rapport=<relevé>` depuis la racine du dépôt ; si l'empreinte diverge, une seule reprise au repos avant toute escalade ; le commit d'armement (deux constantes + `TABLE_ATTENDUE`, trailer du plan) n'est à poser que sur deux comptes nuls et deux lignes d'empreinte identique.

## Files Created/Modified

- `plugin/planning-core/scripts/planning-hook.sh` : G6, identité, F6, F7b, G5 par lien dur
- `plugin/planning-core/scripts/check-gates-alive.sh` : trois cas, type « observation » (`NOM_ETAT` composé : le recensement des consommateurs refuse un chemin de planning suivi de ce nom sur une même ligne)
- `plugin/planning-core/scripts/rejeu-gates.sh` : constructeurs G6 et G5, `charge` d'un Edit
- `plugin/planning-core/scripts/tests/test-planning-gates.sh`, `tests/test-rejeu-gates.sh`, `tests/fixtures/gates-banc.txt` : cas, mutants, labs `g6-adherent` et `g6-dev`
- `plugin/_internal/tests/test-planning-hook-installed.sh` : R-CAN-05 et MUT-CAN-SANS-CAS
- `.planning/.../45-REJEU-ETAPE-1.md` (créé)

## Decisions Made

Voir `key-decisions`. Arbitrages humains invoqués : F6, F7b et rejeu-oui (Willy, AskUserQuestion session principale, 2026-09-30, relayés par le dispatcher).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `test-planning-hook-installed.sh` (R-CAN-05, MUT-CAN-SANS-CAS) n'est pas dans `files_modified`**
- **Found during :** Tâche 1 (le `<verify>` du plan lance cette suite).
- **Issue :** ces deux assertions armaient G6 et G5 pour prouver « gate armé sans canary » ; G6 et G5 ayant désormais leurs cas de canary, le signal n'a plus lieu et la suite rougissait.
- **Fix :** elles arment G6, G5 et G1 (ordre des étapes respecté) et attendent `gate armé sans canary : G1` ; même preuve, sur un gate qui n'a pas encore de cas.
- **Files modified :** plugin/_internal/tests/test-planning-hook-installed.sh ; **Commit :** `174027d`.

**2. [Rule 1 - Bug, dans mon brouillon] Commande enregistrée avec un chemin absolu : D01 à D03 du canary en échec dans R-CANG-01/02**
- **Found during :** Tâche 1. Mes premiers R-CANG substituaient le jeton par un chemin absolu ; le mode `script-absent` du canary (qui redirige `CLAUDE_PROJECT_DIR`) n'avait alors plus d'effet.
- **Fix :** la suite pose le jeton à la forme du scope projet (`"$CLAUDE_PROJECT_DIR"/.claude/scripts`), comme l'installeur, et lance le canary avec ce projet. **Commit :** `174027d`.

**3. [Rule 1 - Bug, dans mon brouillon] Dérogation active dans le banc**
- **Found during :** Tâche 1. Mon premier `derogations-gates.log` du lab `g6-adherent` portait une dérogation G6 sur l'état, donc non consommée et active : les `doit-refuser` passaient. Le journal du banc porte une dérogation G1 sur un livrable, et R-G6-05 repart d'un journal neuf. **Commit :** `174027d`.

**4. [Rule 3 - Blocking] Lint des consommateurs de planning**
- **Found during :** Tâche 1. `check-planning-consumers-registered.sh` a refusé `check-gates-alive.sh` (un chemin de planning et le nom de l'état sur une même ligne du cas de canary). Nom composé par concaténation (`NOM_ETAT`), conformément à la consigne de la recherche. **Commit :** `174027d`.

### Écarts de mise en oeuvre (sans changement de contrat)

**5. Edit de config.json du rejeu.** Le plan fait réécrire `config.json` avec `planning_version "2.0"` (doit-refuser) et à l'identique (doit-passer) sous la même clé `(Write, chemin)`, ce que « un seul attendu par clé » interdit. Retenu : le doit-refuser est un Edit dont la charge passe par un sixième élément facultatif du tuple de constructeur (`charge`) ; clé `(Edit, config.json)` distincte, deux lignes distinctes au relevé.

**6. Isolement des essais.** Les constructeurs livrés G6 et G5 jouent dans tout rejeu : les essais de `test-rejeu-gates.sh` qui utilisent un substitut de hook retirent ces deux constructeurs (scénario `aucun`), sans quoi chaque compte asserté changerait. Le test R-REJEU-G6G5 et R-REJEU-06 rejouent le vrai hook et les vrais constructeurs.

**7. Casse sur un système sensible à la casse.** Le plan parle d'un jumeau « ne refuse pas à tort » pour `state.md` hors APFS ; le même plan fixe la création par casefold, qui refuse. Retenu : le casefold refuse partout (Pattern 5 accepte cet excès), sans jumeau de casse ; le mutant de casse est opposable sur tout système (création d'un nom protégé absent en autre casse).

**8. Lien dur de G5 hors du dossier de planning.** Un lien dur vers un VERDICT.md écrit sous un autre nom hors du dossier de planning est refusé aussi (il modifie le même inode) : plus large que la lettre du plan (« contre chaque VERDICT.md du planning »), jamais un faux refus sur un fichier qui n'est pas un lien dur vers un verdict.

### Déviations d'environnement (à signaler)

- **Charge machine élevée** (load average 16 à 63, autres agents) : durées de suites non représentatives (`test-planning-gates.sh` 278 s puis 154 s).
- **Garde d'isolation du poste** : refus de commandes composées (`cd … && …`, heredoc suivi d'un `&&`) ; chaque commande a été lancée seule, les suites longues en arrière-plan et attendues jusqu'à leur fin. Aucun `HOME=` préfixé, aucun repli harnais nécessaire (le rejeu réel n'a pas été lancé).
- **Registre du HEAD de départ hors du dossier git** : `plan_head_before` (`d88d685`) est consigné ici et `commits:` mesuré par `git rev-list --count`.
- **Décision relayée, pas posée en direct** : F6, F7b et rejeu-oui sont arrivés par le dispatcher (canal cité : Willy, AskUserQuestion session principale, 2026-09-30).

## Auth gates

Aucune.

## Suites rejouées (aucune affectation de HOME ; découverte complète NON lancée)

| Suite | Résultat |
|---|---|
| planning-core/test-planning-gates.sh | 147 OK · 0 KO |
| planning-core/test-rejeu-gates.sh | 38 OK · 0 KO |
| _internal/test-planning-hook-installed.sh | 19 OK · 0 KO |
| planning-core/test-planning-hook-registered.sh | 37 OK · 0 KO |
| planning-core/test-recalc-planning.sh (une fois, en fin de plan ; fichier non touché) | 347 OK · 0 KO |
| planning-core/test-check-planning-state.sh | 19 ok · 0 ko |
| planning-core/test-detect-gsd-engine.sh | 26 ok · 0 ko |
| planning-core/test-detect-planning-debt.sh | 10 passés · 0 échoués |
| planning-core/test-planning-context-hardening.sh | 38 passés · 0 échoués |
| planning-core/test-planning-core.sh | 14 passés · 0 échoués |
| planning-core/test-planning-hooks.sh | 42 PASS · 0 FAIL |
| planning-core/test-workstream-policy.sh | 22 ok · 0 ko · 0 skip |
| planning-core/test-workstream-symlink-escape.sh | 10 ok · 0 ko |
| conductor/check-planning-consumers-registered.sh | ✓ 22 consommateurs, tous recensés |
| scripts/check-machine-paths.sh | ✓ aucun chemin absolu de machine (relevé compris) |
| 45-CONTROLE-MARQUEUR.sh `--base=fd49137` | hook et canary : `sans-marqueur=0` ; hook, rejeu, suite du rejeu : `MARQUEUR-BILAN commits=9 sans-marqueur=0` |

## Limites déclarées portées par ce plan

- **G6 est un refus de l'outil, pas du disque** : `Bash` et `recalc-planning.sh` écrivent ces fichiers sans passer par le hook (R-ID-05), par construction (limite Bash déclarée, P45-D-10).
- **Seuil de juge** (spec §10) : aucune clé du modèle de la 44 ne le porte, donc rien à protéger dans `config.json` ; signalé.
- **Lien dur de G5** : parcours borné à 20000 entrées du dossier de planning ; au-delà, un lien dur vers un verdict trouvé plus loin ne serait pas vu.
- **Casse** : sur un système sensible à la casse, un fichier distinct nommé `state.md` est refusé par excès (Pattern 5).
- **Rejeu réel non fait** : aucune mesure sur ~/jarvis-keystone ni ~/BusinessFlow-Lab ; les attendus « refus conforme au modèle » des STATE.md et INDEX.md écrits à la main des deux labs (5 + 8 et 2 + 1, mesure du 2026-09-29) sont donc seulement prévus par le constructeur G6, pas encore observés.

## Known Stubs

Aucun.

## Threat Flags

Aucune surface nouvelle hors du `<threat_model>` du plan. T-45-40 à T-45-42 (écriture à la main d'un fichier généré, contournement par identité, désarmement par config.json) sont mitigés et prouvés en CI par une suite qui rougit, mais l'effet de T-45-40 à T-45-43 reste conditionné à l'armement ; T-45-43 et T-45-44 (faux refus massif, écriture dans un lab réel) sont tenus par la règle d'armement : rien n'a été lu ni armé sur les labs réels.

## Étapes du workflow sautées (consigne du dispatcher, ADR-063)

Aucune commande `gsd-tools state <verbe>`, aucune écriture de `STATE.md` ni de `ROADMAP.md`, pas de `requirements mark-complete` : à la charge de l'orchestrateur (exigences GATE-04, GATE-05, GATE-11, GATE-12, GATE-13, GATE-15 ; GATE-13 et l'armement de GATE-04 et GATE-05 sont conditionnés au rejeu réel, donc ouverts).

## Deferred Issues

- Rejeu réel de l'étape 1 et armement éventuel de G6 et G5 : à reprendre quand `~/BusinessFlow-Lab` est au repos (voir le relevé).
- `test-vibeflow-update.sh` (18 KO préexistants relevés en 45-01) n'a pas été rejoué.

## Self-Check: PASSED

Vérifié par commandes : les fichiers modifiés et le relevé existent ; les trois commits de tâche (`174027d`, `186daa3`, `580153f`) sont ancêtres de HEAD ; `ARMEMENT_G6` et `ARMEMENT_G5` valent `"observe"` ; le relevé et ce SUMMARY ne portent aucun chemin absolu de machine.
