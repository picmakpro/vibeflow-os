---
phase: 44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque
plan: 01
subsystem: planning-core
tags: [python, bash, planning-engine, cycles-v1, gsd-detection, mutation-testing]

requires: []
provides:
  - "recalc-planning.sh : point d'entrée bash mince + moteur Python embarqué (heredoc quoté), traceur du modèle par cycles"
  - "Refus d'écriture sans adhésion explicite (\"planning_version\": \"cycles-v1\") — P44-D-02"
  - "Refus d'écriture sur un planning tenu par le moteur GSD, y compris quand la chaîne GSD est absente de la machine (lecture indépendante de STATE.md, racine puis compartiments) — P44-D-02a, P44-D-01b, P44-D-01c"
  - "Mode --read-only : dérivation JSON déterministe, aucune écriture, jamais d'invocation du détecteur GSD"
  - "Écriture déterministe et idempotente de INDEX.md/STATE.md, journal cloture.log en ajout seul dédupliqué"
  - "Banc synthétique versionné (recalc-planning-banc.txt) et suite bash (test-recalc-planning.sh, R01-R14, 12 mutants, 3 gardes de harnais)"
affects: ["44-02", "44-03", "44-04", "45", "46", "47", "48", "49", "50"]

actuals:
  tokens: 24250
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Python 3.9+ stdlib embarqué en heredoc quoté dans un .sh (voie a de P44-D-14, patron dag.sh) — l'installeur ne pose que *.sh/*.mjs/*.js exécutables et *.txt/*.json en données, jamais de .py"
    - "Écriture atomique par tempfile.mkstemp + os.fchmod + os.fdopen + os.replace, jamais un save() non atomique"
    - "Ouverture O_NOFOLLOW pour toute lecture/écriture de fichier du modèle (lstat régulier + os.open O_NOFOLLOW pour les lectures ; échec ELOOP explicite pour cloture.log)"
    - "Détection GSD fail-closed : incertitude (détecteur absent/irrégulier/non concluant) => refus, jamais un vert par défaut"
    - "Mutation testing bash : make_recalc_mutant (patron test-check-skills.sh make_gate_mutant) avec prédicat de mort explicite (traceback ou code hors contrat 0/1/2/3/64 => NON TUÉ automatique, appliqué par le mécanisme, jamais une convention documentée seule)"
    - "Banc synthétique versionné en fichier texte plat (format @@), matérialisé en lab temporaire par un aide Python dédié — jamais un dossier .planning/ versionné dans le dépôt"

key-files:
  created:
    - plugin/planning-core/scripts/recalc-planning.sh
    - plugin/planning-core/scripts/tests/test-recalc-planning.sh
    - plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt
  modified:
    - README.md
    - README.fr.md

key-decisions:
  - "Voie (a) de P44-D-14 : moteur Python embarqué en heredoc quoté (PY_RECALC_PLANNING_EOF) dans recalc-planning.sh, jamais un fichier .py séparé — l'installeur ne poserait jamais ce dernier chez un utilisateur."
  - "Ajout d'un commentaire inerte distinct par ligne de retour dans detection_gsd() (# motif-code-0, # motif-detecteur-irregulier, etc.) pour rendre chaque garde individuellement ciblable par make_recalc_mutant à motif unique — comportement inchangé, correction de testabilité (commit fix(44-01) distinct)."
  - "compte_par_etat / compte_cycles_par_etat du rapport --read-only comptent les onze états du modèle (8 dérivables + 3 dérogations non dérivables), zéros compris, même si le traceur ne produit lui-même que close/à exécuter/indéterminé — l'interface complète est posée dès 44-01 pour que 44-02/44-03/44-04 l'étendent sans la casser."
  - "CPR-0 (check-planning-consumers-registered.sh) : recalc-planning.sh évite délibérément le littéral \".planning/workstreams\" et \".planning/\" suivi de STATE.md/ROADMAP.md/REQUIREMENTS.md sur la même ligne (variables planning_abs / dossier de planning uniquement) — le lint reste vert sans recensement dans workstream-planning-consumers.md, conformément au repli explicitement autorisé par le plan quand aucun littéral déclencheur n'est présent."

requirements-completed: [MOTR-02, MOTR-03, MOTR-04, MOTR-10, MOTR-11, MOTR-12, MOTR-14, MOTR-15, MOTR-16]

coverage:
  - id: D1
    description: "recalc-planning.sh dérive le lab traceur (un cycle, deux phases) et écrit INDEX.md/STATE.md/cloture.log de façon déterministe et idempotente"
    requirement: "MOTR-10"
    verification:
      - kind: integration
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — R01 (coureur du banc), R02, R03"
        status: pass
    human_judgment: false
  - id: D2
    description: "Refus d'écriture sans adhésion explicite (P44-D-02) et sur un planning GSD détecté ou non concluant, y compris via la lecture indépendante de STATE.md racine/compartiments quand la chaîne GSD est absente de la machine (P44-D-02a, P44-D-01b, P44-D-01c)"
    requirement: "MOTR-02"
    verification:
      - kind: integration
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — R04, R05, R08, R09, R13"
        status: pass
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — MUT-ADHESION, MUT-GSD, MUT-GSD-FERME, MUT-GSD-IRREGULIER, MUT-CHAINE-ABSENTE, MUT-PARTITION-ABSENTE"
        status: pass
    human_judgment: false
  - id: D3
    description: "Mode --read-only : dérivation sans écriture, sans jamais invoquer detect-gsd-engine.sh"
    requirement: "MOTR-03"
    verification:
      - kind: integration
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — R06, R07 (sentinelle)"
        status: pass
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — MUT-LECTURE-SEULE"
        status: pass
    human_judgment: false
  - id: D4
    description: "Journal cloture.log en ajout seul, dédupliqué, refuse d'écrire à travers un lien symbolique"
    requirement: "MOTR-11"
    verification:
      - kind: integration
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — R10, R11"
        status: pass
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — MUT-AJOUT, MUT-DEDOUBLONNAGE, MUT-NOFOLLOW"
        status: pass
    human_judgment: false
  - id: D5
    description: "Permissions 0o644 forcées par fchmod explicite, indépendantes du umask du processus"
    requirement: "MOTR-10"
    verification:
      - kind: integration
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — R14"
        status: pass
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — MUT-CHMOD, MUT-CHMOD-JOURNAL"
        status: pass
    human_judgment: false
  - id: D6
    description: "Livraison lab frais : recalc-planning.sh, sa suite et son banc arrivent dans .claude/scripts/ par l'installeur inchangé, suite installée verte"
    requirement: "MOTR-14"
    verification:
      - kind: e2e
        ref: "commande TRACER-LAB-FRAIS-OK (HOME temporaire, install planning-core, suite installée exécutée)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Mécanisme de mutation testing (make_recalc_mutant) : mutant Python invalide rejeté, refus compté KO dans le shell appelant, prédicat de mort explicite (plantage ou code hors contrat) appliqué avant toute comparaison métier"
    requirement: "MOTR-16"
    verification:
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh — MUT-SYNTAXE, MUT-REFUS-COMPTE, MUT-PLANTAGE"
        status: pass
    human_judgment: false

duration: ~2h (non chronométré précisément au lancement — session unique)
completed: 2026-09-28
status: complete
---

# Phase 44 Plan 01: Traceur du moteur de recalcul d'état dérivé du disque Summary

**`recalc-planning.sh` dérive du disque l'état d'un lab par cycles (un cycle, deux phases) et écrit `INDEX.md`/`STATE.md`/`cloture.log` de façon déterministe, avec un refus fail-closed sur toute non-adhésion ou tout planning GSD (détecté ou incertain) — chacune de ses 12 gardes prouvée par un mutant dédié, chacune de ses 3 gardes de harnais prouvées à leur tour.**

## Performance

- **Duration:** ~2h (démarrage non chronométré via `PLAN_START_TIME` — session d'exécution unique, longue et continue)
- **Completed:** 2026-09-28
- **Tasks:** 2/2
- **Files modified:** 5 (3 créés, 2 modifiés)
- **Commits:** 4 (mesuré : `git rev-list --count 6296b54..HEAD`)

## Accomplishments

- Point d'entrée bash mince (`recalc-planning.sh`) + moteur Python 3.9+ stdlib embarqué en heredoc quoté (voie a de P44-D-14, patron `dag.sh`), qui dérive `cycles/`, `CYCLE.md`, `CADRAGE.md`, `PLAN.md`, le marqueur `CLOTURE.md`, `VERDICT.md`, `SUMMARY.md` selon la grammaire de frontmatter minimale du contrat (jamais un devin — toute forme non reconnue rend `indéterminé`).
- Deux refus fail-closed, jamais dispersés : non-adhésion (`.planning/config.json` doit déclarer exactement `"planning_version": "cycles-v1"`, P44-D-02) et planning GSD détecté ou incertain (P44-D-02a), y compris quand la chaîne GSD est absente de la machine — le moteur lit alors lui-même `STATE.md` (racine puis compartiments `workstreams/*/STATE.md`) sans jamais dépendre de `detect-gsd-engine.sh` ni de ses suites (P44-D-01b, P44-D-01c).
- Mode `--read-only` : une seule garde en tête de `main()`, sortie avant toute fonction d'écriture — ni fichier généré, ni cache, ni sous-processus détecteur.
- Écriture atomique (`tempfile.mkstemp` + `os.fchmod` + `os.replace`) et déterministe de `INDEX.md`/`STATE.md` ; `cloture.log` en ajout seul, déduplication lue dans le journal lui-même, refus fail-closed (code 1) sur un lien symbolique via `SANS_SUIVI_DE_LIEN`.
- Permissions `0o644` forcées par `fchmod` explicite sur chaque descripteur, indépendantes du `umask` du processus appelant.
- Banc synthétique versionné (`recalc-planning-banc.txt`, format `@@`, 3 labs : `traceur`, `traceur-gsd`, `traceur-gsd-partition`) et suite bash (`test-recalc-planning.sh`) : R01 à R14, douze mutants de garde tracés (assertion/attendu original/obtenu mutant), trois gardes du harnais lui-même (dont `MUT-PLANTAGE`, dont le mécanisme applique un prédicat de mort explicite avant toute comparaison métier).
- Livraison confirmée dans un lab frais par l'installeur **inchangé** (`TRACER-LAB-FRAIS-OK` sous `HOME` temporaire).

## Task Commits

Chaque tâche a été committée atomiquement :

1. **Tâche 1 : traceur — du banc au lab frais** :
   - `55354f4` `feat(planning-core): recalc-planning.sh — traceur du moteur de recalcul d'état (44-01)`
   - `97a0bbb` `docs(readme): compteur de suites 90 → 91 (test-recalc-planning.sh, 44-01)`
2. **Tâche 2 : gardes du traceur prouvées rouges** :
   - `6d1b7c2` `fix(44-01): motifs uniques par ligne dans detection_gsd pour les mutants de garde`
   - `8aed275` `test(44-01): gardes du traceur prouvées rouges — adhésion, lecture seule, GSD (chaîne présente et absente), journal en ajout seul (P44-D-01b, P44-D-01c, P44-D-02, P44-D-02a, P44-D-11, P44-D-17)`

**Plan metadata:** ce commit (`docs(44-01): ...`, ajouté par l'orchestrateur après la vague — hors périmètre de cet agent).

## Files Created/Modified

- `plugin/planning-core/scripts/recalc-planning.sh` — point d'entrée bash + moteur Python embarqué : `lire_frontmatter`, `verifier_adhesion`, `detection_gsd`, `scanner`, `deriver_feuille`, `agreger`, `deriver_cycle`, `lire_journal`, `lignes_a_journaliser`, `ajouter_au_journal`, `LIBELLES`, `libelle_raison`, `libelle_cycle_indetermine`, `rendre_index`, `rendre_state`, `ecrire_si_different`, `appliquer_ecritures`, `main`.
- `plugin/planning-core/scripts/tests/test-recalc-planning.sh` — suite R01-R14, coureur du banc, aides Python (`materialiser`/`empreinte`/`coureur`), `make_recalc_mutant`, douze `MUT-*`, trois gardes du harnais.
- `plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt` — banc synthétique versionné (format `@@`), labs `traceur`, `traceur-gsd`, `traceur-gsd-partition`.
- `README.md` / `README.fr.md` — compteur de suites 90 → 91.

## Decisions Made

- **Voie (a) de P44-D-14** confirmée et implémentée : moteur Python embarqué en heredoc quoté (`<<'PY_RECALC_PLANNING_EOF'`), aucun fichier `.py` séparé, aucun changement de l'installeur.
- **Motifs uniques par ligne dans `detection_gsd()`** (déviation Rule 3, voir ci-dessous) : chaque `return` de la fonction porte désormais un commentaire inerte distinct, sans quoi `make_recalc_mutant` ne pouvait pas cibler individuellement `MUT-GSD`, `MUT-GSD-FERME`, `MUT-CHAINE-ABSENTE`, `MUT-PARTITION-ABSENTE` (motif à occurrence unique exigé par le patron `make_gate_mutant`).
- **`compte_par_etat`/`compte_cycles_par_etat`** couvrent les onze états du modèle complet (8 dérivables + 3 dérogations), zéros compris, dès 44-01 — bien que le traceur lui-même ne produise que `close`/`à exécuter`/`indéterminé` — pour que 44-02/44-03/44-04 étendent l'interface sans la casser.
- **CPR-0 sans recensement** : `recalc-planning.sh` n'écrit jamais le littéral `.planning/workstreams` ni `.planning/` suivi de `STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md` sur la même ligne (toujours via la variable `planning_abs`) ; `check-planning-consumers-registered.sh` reste vert (`21 consommateur(s) détecté(s), tous recensés`) sans ajout à `plugin/conductor/references/workstream-planning-consumers.md` — conforme au repli explicitement prévu par le plan (action 5) quand aucun littéral déclencheur n'est présent. `bash scripts/check-version-sync.sh` confirmé vert par ailleurs (compteur de suites, non un bump de version — `conductor` n'a pas été touché).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Motifs de mutation non uniques dans `detection_gsd()`**
- **Found during:** Tâche 2, action 3 (construction de `make_recalc_mutant`)
- **Issue:** chaque `return "gsd"` / `return "non-gsd"` / `return "non-concluante"` de `detection_gsd()` partageait son texte avec au moins une autre ligne du fichier (ex. `return "gsd"` apparaît 4 fois) — `make_recalc_mutant` exige un motif à occurrence UNIQUE (`grep -Fc` = 1) pour cibler une ligne sans ambiguïté, patron `test-check-skills.sh` `make_gate_mutant`. Sans correctif, `MUT-GSD`, `MUT-GSD-FERME`, `MUT-CHAINE-ABSENTE`, `MUT-PARTITION-ABSENTE` auraient été irréalisables.
- **Fix:** ajout d'un commentaire inerte distinct en fin de chacune des neuf lignes `return` de `detection_gsd()` (`# motif-code-0`, `# motif-detecteur-irregulier`, `# motif-sous-processus-en-echec`, `# motif-code-2-ou-3`, `# motif-marqueur-racine`, `# motif-marqueur-compartiment`, `# motif-partition-compartiment`, `# motif-code-1-sans-marqueur`, `# motif-repli-generique`). Comportement runtime strictement inchangé (vérifié par ré-exécution complète de R01-R04 après l'édit, avant toute autre modification).
- **Files modified:** `plugin/planning-core/scripts/recalc-planning.sh`
- **Verification:** `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` → `67 OK · 0 KO` ; `bash -n` + compilation du corps Python du heredoc → OK.
- **Committed in:** `6d1b7c2` (commit `fix(44-01)` distinct, conformément à l'action 7 du plan).

---

**Total deviations:** 1 auto-fixée (Rule 3 — testabilité, aucun changement de comportement).
**Impact on plan:** aucun — correctif nécessaire pour que les mutants de garde exigés par le plan soient réalisables ; pas de dérive de périmètre.

## Issues Encountered

None au-delà de la déviation ci-dessus. Le bug de grammaire du banc (`@@ #` sans texte, non reconnu par le parseur `parser_banc` au premier essai) a été trouvé et corrigé pendant le développement de la suite, avant tout commit — pas une déviation du plan exécuté, un défaut de la première itération de l'outillage de test lui-même.

## User Setup Required

None — aucune configuration de service externe requise.

## Next Phase Readiness

- Le contrat de 44-01 (commande, codes de sortie, formats JSON lecture-seule/écriture, grammaire de frontmatter, règle d'agrégation de cycle, libellés lisibles des raisons `indéterminé`) est fixé et prouvé sur le traceur ; 44-02 peut rédiger la référence du modèle complet et les gabarits sans re-discuter ce contrat.
- 44-03/44-04 étendent le même fichier (`recalc-planning.sh`, `test-recalc-planning.sh`, `recalc-planning-banc.txt`) avec la matrice des huit états, le hors-modèle, le cache incrémental — les interfaces (`hors_modele: []`, `compte_par_etat`/`compte_cycles_par_etat` sur onze états, `plans: []`) sont déjà posées pour ne pas casser 44-01.
- Aucun blocage. Aucune release (jalon gouvernance, gates rejoués à la main tant que la Phase 41.1 n'est pas mergée — hors périmètre de ce plan).

---
*Phase: 44-moteur-modele-de-donnees-et-recalcul-d-etat-derive-du-disque*
*Plan: 01*
*Completed: 2026-09-28*

## Self-Check: PASSED

- All 4 created/modified deliverable files found on disk (`recalc-planning.sh`, `test-recalc-planning.sh`, `recalc-planning-banc.txt`, this SUMMARY.md).
- All 4 task commits (`55354f4`, `97a0bbb`, `6d1b7c2`, `8aed275`) found in `git log`.
- `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` → `67 OK · 0 KO` (rerun immediately before this check).
