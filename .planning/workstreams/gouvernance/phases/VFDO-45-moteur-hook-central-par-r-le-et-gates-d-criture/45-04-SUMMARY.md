---
phase: 45-moteur-hook-central-par-r-le-et-gates-d-criture
plan: 04
subsystem: planning-core (entonnoir de décision du hook central, G5, commandes de verdict et de dérogation)
tags: [hook, entonnoir, observe-armed, g5, verdict, derogation, journal-append-only, r-env-02, mutation-testing]

requires:
  - phase: 45-01
    provides: planning-hook.sh (phase A/B, evaluer_gates, constantes ARMEMENT_*), suite test-planning-gates.sh et banc
  - phase: 45-02
    provides: journal de dérogation F7a = f7a-racine (.planning/derogations-gates.log), déclaré au modèle
provides:
  - "planning-hook.sh : Verdict, decider() (refus si armed, ligne d'observation si observe, citation si dérogation consommée), observer(), evaluer_g5, derogation_active / consommer"
  - "poser-verdict.sh : seul chemin légitime vers VERDICT.md (sha256 du PLAN.md, tentative 1 puis +1, écriture atomique)"
  - "deroger-gate.sh : dérogation nominative, journal append-only à encodage injectif, usage unique"
  - "test-planning-gates.sh : R-G5-01..06, R-OBS-ENV, R-JETON, R-VERDICT-01..05, R-DEROG-01..08, R-ENV-02 amendé, 16 nouveaux mutants"
  - "gates-banc.txt : labs g5-adherent et g5-dev, option `armee`, COUVERTURE G5"
affects: [45-05, 45-06, 45-07, 45-08, 45-09, 45-10]

plan_head_before: 3682ad6111451494c4801dcd1cd97c83c92ed151
estimate:
  tokens: 140000
  raw_tokens: 140000
  tasks: 3
  confidence: low
actuals:
  tokens: 24000    # chars/4 sur les lignes ajoutées du diff réalisé (git diff -U0 base..HEAD sous plugin/, 105864 caractères tous types de lignes confondus, ordre de grandeur), hors ce SUMMARY
  tasks: 3
  commits: 3       # MESURÉ : git rev-list --count 3682ad6..HEAD avant le commit de ce SUMMARY

tech-stack:
  added: []
  patterns:
    - "entonnoir unique : chaque gate rend des Verdict(gate, chemin_rel, raison), decider() est le seul endroit où un verdict devient refus, observation ou passage cité"
    - "garde à point d'ouverture unique : _ouvrir_journal_derogations porte le lstat ET l'ouverture O_NOFOLLOW sur UNE ligne, lecture et consommation passent par là ; la re-vérification sous verrou de consommer() réutilise _derogation_non_consommee : une garde dupliquée rendrait le mutant non opposable"
    - "copie forcée du hook (ctx.copie_forcee) : les cas de gate rejouent une copie dont les cinq ARMEMENT_* valent observe ou armed, jamais l'état livré"
    - "valeurs d'environnement lues par le seul lanceur et passées en arguments (sys.argv[2], sys.argv[3]) au seul chemin du journal"

key-files:
  created:
    - plugin/planning-core/scripts/poser-verdict.sh
    - plugin/planning-core/scripts/deroger-gate.sh
  modified:
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/scripts/tests/fixtures/gates-banc.txt

key-decisions:
  - "Amendement de R-ENV-02 (décisions du manager vf-dev-manager, 2026-09-30, décision B1 du plan) : le lanceur lit XDG_CACHE_HOME et HOME, une fois chacune, sur la seule ligne d'appel du cœur ; le cœur reste sans aucune lecture d'environnement (expanduser et expandvars ajoutés à la garde) ; lecture et garde dans le MÊME commit, trailer Gate-Touche"
  - "F8 = f8-agnostique et A3 = a3-plan (Willy, AskUserQuestion session principale, 2026-09-30, relayés par l'orchestrateur au checkpoint de la Tâche 2) : commande agnostique de l'appelant, --juge obligatoire ; sha256 des octets du PLAN.md de l'unité"
  - "Un VERDICT.md qui n'est pas un fichier régulier (lien) n'est pas un verdict existant : poser-verdict.sh le remplace par os.replace sans jamais le suivre, tentative 1 (alignement sur ecrire_si_different du moteur de recalcul) ; choix d'exécution sous le plan, qui ne tranchait pas ce cas"
  - "Journal d'observation : XDG_CACHE_HOME absolu, à défaut HOME/.cache absolu, sinon aucune ligne ; pas de repli sur HOME si XDG est exploitable mais non inscriptible (la valeur exploitable fixe le chemin, l'échec d'écriture n'est jamais un refus)"
  - "Une dérogation est relue et re-validée sous verrou avant consommation : une consommation concurrente ne laisse pas passer deux actions avec une dérogation à usage unique"

requirements-completed: [GATE-05, GATE-11, GATE-02, GATE-13, GATE-15]

status: complete
---

# Phase 45 Plan 04: Entonnoir de décision, G5, commande de verdict, dérogation nominative Summary

**Tout gate qui refuse passe désormais par un seul entonnoir (refus armed, ligne d'observation hors du lab, passage cité par dérogation), G5 en est le premier client et reste en observation, le verdict ne s'écrit que par `poser-verdict.sh` (hash et tentative calculés par la commande) et la dérogation est nominative, à usage unique et jamais liée à l'urgence.**

## Performance

- **Tâches :** 3/3 (Tâche 1 tracer, Tâche 2 point de décision F8/A3, Tâche 3 auto tdd)
- **Commits de tâche :** 3 (mesuré depuis `plan_head_before`) ; la Tâche 2 est une décision, sans commit
- **`test-planning-gates.sh` :** 47 OK avant le plan (45-01) -> **104 OK · 0 KO**, dont 27 mutants tués (10 + 2 + 4 nouveaux de ce plan en plus des 9 de 45-01 et 2 de la correction ciblée)

## Accomplishments

- **Entonnoir.** `decider(verdicts, contexte)` : gate armed -> refus (raisons concaténées en UN objet deny, code 0) sauf dérogation active ; gate en observe -> une ligne au journal d'observation et rien au modèle ; erreur interne d'un gate -> `Verdict` d'erreur, deny si armed, ligne d'observation sinon (P45-D-03a, P45-D-08).
- **Journal d'observation.** `${XDG_CACHE_HOME}/vibeflow/gates-observation/observation.log`, à défaut `${HOME}/.cache/...`, ajout seul, O_NOFOLLOW, 0600 (dossier 0700), jamais le contenu ni la commande (R-G5-06). Un journal impossible à écrire ne devient jamais un refus (R-OBS-ENV).
- **G5.** Write, Edit, NotebookEdit d'un fichier nommé VERDICT.md (casse ignorée, `.planning` comparé par casefold) sous le `.planning/` d'un lab adhérent, tout rôle compris ; chemin résolu physiquement ; le motif nomme `poser-verdict.sh`. **Toujours en observation** (`ARMEMENT_G5 = "observe"`) : l'armement vient avec G6 en 45-05.
- **Amendement de R-ENV-02.** Garde statique réécrite : cœur sans `environ`, `getenv`, `putenv`, `expanduser`, `expandvars` ; lanceur : TMPDIR une fois sur la ligne du mktemp, XDG_CACHE_HOME et HOME une fois chacune sur la seule ligne qui appelle `"$PYBIN"`. MUT-ENV-STATIQUE et MUT-ENV-LANCEUR restent tués ; MUT-ENV-EXPANDUSER, MUT-OBS-ARMEMENT (une valeur reçue ne change pas l'armement) et MUT-OBS-ADHESION (ni l'adhésion) ajoutés.
- **`poser-verdict.sh`.** Format du gabarit de la 44 ; hash = sha256 des octets du PLAN.md (A3) par hashlib ; tentative 1 à la création, ancienne + 1 pour remplacer (sinon 64, fichier inchangé par cmp) ; écriture atomique (mkstemp dans le dossier de l'unité, fchmod 0644, os.replace) ; 2 hors lab adhérent, 64 pour une unité hors `.planning/cycles/`, sans PLAN.md, un constat invalide ou une valeur qui ne se relit pas à l'identique ; `recalc-planning.sh --read-only` relit tentative, hash et l'état `close` (R-VERDICT-03) ; lancée par Bash alors que G5 est armé, elle écrit (R-VERDICT-05).
- **`deroger-gate.sh`.** Journal `.planning/derogations-gates.log` (F7a), une ligne par chemin, ids incrémentés, champs en encodage pourcent injectif (copie ast-identique), ajout seul sous `fcntl.flock`, saut de ligne ajouté si le journal n'en finit pas par un ; raison vide, TODO, xxx, ellipse ou `<...>` refusée après NFKC, pleine chasse comprise ; aucune option ni horloge ne conditionne l'acceptation (R-DEROG-08).
- **Dérogation côté hook.** `derogation_active` (lecture) puis `consommer` (relecture sous verrou, ligne `consommee`) ; citation `[planning-core] dérogation #<id> consommée pour <gate> sur <chemin> — accordée par <qui> (<canal>, <date>) : <raison>` dans additionalContext ; sans effet en observe ; un journal non régulier annule toute dérogation.
- **Banc.** Labs `g5-adherent` (8 doit-refuser, 6 doit-passer) et `g5-dev` jumeau (2 silence), rejoués sur copie armée par l'option `armee` ; 0 faux refus, 0 faux accept.

## Task Commits

1. **Tâche 1 (tracer) :** `9a23c12` — entonnoir de décision, journal d'observation et G5 en observation ; R-ENV-02 amendé dans le même commit (deux trailers Gate-Touche, corps citant « décisions du manager vf-dev-manager, 2026-09-30 »).
2. **Tâche 2 (checkpoint:decision) :** aucune modification ; F8 = f8-agnostique, A3 = a3-plan (Willy, AskUserQuestion session principale, 2026-09-30, relayé par l'orchestrateur).
3. **Tâche 3 :** `1d197ef` — commande poser-verdict.sh (GATE-05) ; `f84c54b` — dérogation nominative, journal append-only, usage unique cité (GATE-11).

**Tracer feedback gate** (avant Tâche 2) : `<verify>` de la Tâche 1 rejoué de bout en bout, vert : « Tracer verified end-to-end — expanding ».

## Files Created/Modified

- `plugin/planning-core/scripts/planning-hook.sh` — entonnoir, observation, G5, dérogations ; lanceur passe XDG_CACHE_HOME et HOME au cœur
- `plugin/planning-core/scripts/poser-verdict.sh` (créé) — commande de verdict
- `plugin/planning-core/scripts/deroger-gate.sh` (créé) — commande de dérogation
- `plugin/planning-core/scripts/tests/test-planning-gates.sh` — cas, contrôles et mutants de ce plan, R-ENV-02 amendé
- `plugin/planning-core/scripts/tests/fixtures/gates-banc.txt` — labs g5-adherent et g5-dev

## Decisions Made

Voir `key-decisions`. Aucun arbitrage humain nouveau hors ceux relayés (B1, F8, A3, F7a).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] MUT-DEROG-UNIQUE et MUT-DEROG-LIEN non opposables tant que la garde était dupliquée**
- **Found during:** Tâche 3 (suite complète : `MUT-DEROG-UNIQUE NON TUÉ`, le mutant était « vert »).
- **Issue :** `consommer` refaisait sa propre vérification « déjà consommée » et sa propre garde lstat ; le mutant qui retirait le contrôle dans `derogation_active` restait masqué par la seconde garde, donc indiscernable du code sain.
- **Fix :** un seul point d'ouverture du journal (`_ouvrir_journal_derogations`, lstat et O_NOFOLLOW sur une ligne) et une re-vérification sous verrou qui réutilise `_derogation_non_consommee` (même ligne marquée) ; défense en profondeur conservée sans doublon.
- **Files modified:** plugin/planning-core/scripts/planning-hook.sh
- **Commit:** `f84c54b`

**2. [Rule 2 - Missing critical functionality] Cas `livrables/VERDICT.md` ajouté à R-G5-04 et au banc**
- **Found during:** Tâche 1 (MUT-G5-PERIMETRE ne pouvait pas être tué avec le seul `livrables/verdict-client.md`, dont le nom ne correspond pas à `verdict.md`).
- **Fix :** un VERDICT.md hors `.planning/` est un cas doit-passer de R-G5-04 et du banc.
- **Commit:** `9a23c12`

### Écarts de mise en oeuvre (sans changement de contrat)

**3. Option `armee` du banc.** Le plan demande que le coureur accepte « l'option copie armée » sans en fixer la forme : jeton `armee` sur la ligne `@@ ecriture`, et un cas `doit-passer`/`doit-refuser` sans elle est refusé par le parseur (il dépendrait de l'état livré).

**4. Lien à la place de VERDICT.md.** Le plan ne tranche pas ce cas ; retenu : un lien n'est pas un verdict existant, il est remplacé et jamais suivi (MUT-VERDICT-ATOMIQUE le tue, plié dans R-VERDICT-02 pour garder treize lignes R-VERDICT et R-DEROG).

**5. Mutants hors hook.** `make_script_mutant` généralise `make_hook_mutant` (nom de script et marqueur de heredoc en paramètres) ; un mutant de `poser-verdict.sh` ou de `deroger-gate.sh` reçoit une copie du hook livré pour que le témoin reste rejouable. La boucle de `sec_mutants` accepte des entrées à sept champs.

**6. Fixture de R-VERDICT-03.** La phase du banc porte un dossier `plans/01-a` (cas G5 de profondeur) : le test le retire dans sa copie jetable, sinon la phase dérive `plan-direct-et-plans`.

### Déviation d'environnement (à signaler)

- **`HOME` non jetable par affectation** : comme en 45-02, le garde-fou du poste refuse l'affectation de `HOME` ; chaque suite a été lancée seule en commande simple. Les suites posent leur propre `HOME` temporaire aux enfants ; R-ENV-01 et R-OBS-ENV font varier `HOME` et `XDG_CACHE_HOME` explicitement.
- **Charge machine très élevée** : `test-planning-gates.sh` a pris 445 s puis plus de 500 s (12 s dans le SUMMARY de 45-01) ; durées non représentatives. Les deux dernières exécutions longues ont été lancées en arrière-plan et attendues jusqu'à leur fin : aucun job ni processus enfant ne reste actif.
- **Registre du HEAD de départ hors du dossier git** : comme en 45-01, le garde-fou refuse d'écrire sous `.git/worktrees/...` ; `plan_head_before` est consigné ici et `commits:` mesuré par `git rev-list --count`.
- **Décision relayée, pas posée en direct** : les réponses F8 et A3 sont arrivées par message de l'orchestrateur (canal cité : Willy, AskUserQuestion session principale, 2026-09-30) ; elles correspondent à celles déjà inscrites dans le plan.

## Auth gates

Aucune.

## Suites rejouées (découverte complète NON lancée ; aucune affectation de HOME)

| Suite | Résultat |
|---|---|
| planning-core/test-planning-gates.sh | 104 OK · 0 KO |
| planning-core/test-planning-hook-registered.sh | 37 OK · 0 KO |
| planning-core/test-rejeu-gates.sh | 36 OK · 0 KO |
| planning-core/test-recalc-planning.sh | 347 OK · 0 KO (fichier non touché, non-régression) |
| planning-core/test-check-planning-state.sh | 19 ok · 0 ko |
| planning-core/test-detect-gsd-engine.sh | 26 ok · 0 ko |
| planning-core/test-detect-planning-debt.sh | 10 passés · 0 échoués |
| planning-core/test-planning-context-hardening.sh | 38 passés · 0 échoués |
| planning-core/test-planning-core.sh | 14 passés · 0 échoués |
| planning-core/test-planning-hooks.sh | 42 PASS · 0 FAIL |
| planning-core/test-workstream-policy.sh | 22 ok · 0 ko · 0 skip |
| planning-core/test-workstream-symlink-escape.sh | 10 ok · 0 ko |
| _internal/test-planning-hook-installed.sh | 19 OK · 0 KO |
| conductor/check-planning-consumers-registered.sh | ✓ 22 consommateur(s), tous recensés (recensement inchangé) |
| scripts/check-machine-paths.sh | ✓ aucun chemin absolu de machine |
| 45-CONTROLE-MARQUEUR.sh `--base=fd49137` (quatre fichiers de la Tâche 3) | `MARQUEUR-BILAN commits=7 sans-marqueur=0` |

## État de l'armement

`ARMEMENT_G6`, `ARMEMENT_G5`, `ARMEMENT_G1`, `ARMEMENT_G7`, `ARMEMENT_ROLE` : toutes `"observe"` dans le script livré ; `G2_MODE = "avertit"` ; `TABLE_ATTENDUE` de la suite inchangée.

## Limites déclarées

- **T-45-34** : `deroger-gate.sh` et `poser-verdict.sh` ne peuvent pas savoir qui les lance ; `--qui` et `--juge` sont déclaratifs (à écrire dans la référence, 45-10).
- **Hash** : le sha256 du PLAN.md ne prouve pas que le livrable jugé est celui produit ; la vérification à la clôture est la Phase 46 (A3).
- **F8** : pour trois juges sur quatre (sans Bash), le verdict transite par le manager ; à écrire dans la référence (45-10).
- **Verrou** : `fcntl.flock` quand le module existe ; sinon course locale possible entre deux hooks concurrents.
- **Journal d'observation** : sans rotation dans cette phase (A8).

## Known Stubs

Aucun.

## Threat Flags

Aucune surface nouvelle hors du `<threat_model>` du plan (T-45-30 à T-45-38 mitigés : G5 sans armement encore, encodage injectif, usage unique cité, lstat du journal, journal d'observation sans contenu, écriture atomique, valeurs d'environnement confinées au chemin du journal).

## Étapes du workflow sautées (consigne du dispatcher, ADR-063)

Aucune commande `gsd-tools state <verbe>`, aucune écriture de `STATE.md` ni de `ROADMAP.md`, pas de `requirements mark-complete` : à la charge de l'orchestrateur (exigences GATE-05, GATE-11, GATE-02, GATE-13, GATE-15 couvertes par ce plan).

## Deferred Issues

Aucune issue hors périmètre rencontrée ; `test-vibeflow-update.sh` (18 KO préexistants relevés en 45-01) n'a pas été rejoué.

## Self-Check: PASSED

Vérifié : les fichiers créés (`poser-verdict.sh`, `deroger-gate.sh`) et modifiés existent ; les trois commits de tâche (`9a23c12`, `1d197ef`, `f84c54b`) sont ancêtres de HEAD ; `ARMEMENT_G5` vaut `"observe"`.
