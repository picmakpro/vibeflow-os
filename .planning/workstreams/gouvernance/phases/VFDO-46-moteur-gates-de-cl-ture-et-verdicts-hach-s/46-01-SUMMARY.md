---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 01
subsystem: planning-core (moteur de planning, pose du verdict)
tags: [sha256, empreinte, lstat, O_NOFOLLOW, plafond, derogation, ast-identique, mutants]

requires:
  - phase: 45-moteur-hook-central-par-role-et-gates-d-ecriture
    provides: poser-verdict.sh (A3), journal de derogation (P45-D-13), deroger-gate.sh, hook central et ses copies ast-identiques
provides:
  - predicat unique livrable_present et empreinte_livrables en trois copies ast-identiques (poser-verdict.sh, planning-hook.sh, recalc-planning.sh)
  - VERDICT.md a deux empreintes (hash du PLAN.md, hash_livrables des entrees ecrit:) pose par la seule commande
  - refus de pose (64) sur livrable absent, vide ou lien, ecrit: invalide, borne depassee
  - plafond de 3 tentatives (code 65) et derogation nominative PLAFOND a usage unique
  - forme d'unite .planning/juges/<juge> (artefact hache SORTIE-PIEGEE.md)
affects: [46-02, 46-03, 46-05, 46-06, 46-07, 46-09]

plan_head_before: 164d7537b3f648d576aaf13e555905a9ec4b1cab
estimate:
  tokens: 180000
  raw_tokens: 180000
  tasks: 3
  confidence: low
actuals:
  tokens: 28517    # chars/4 sur les lignes ajoutees et retirees des trois commits (git diff de la base au HEAD), pas un compte du harnais
  tasks: 3
  commits: 3       # MESURE : git rev-list --count 164d7537..HEAD au moment de l'ecriture du SUMMARY (commits de code, hors commit du SUMMARY)

tech-stack:
  added: []
  patterns:
    - "bloc de code partage en copies ast-identiques comparees par la suite (R-EMP-04), faute de module partage"
    - "balise de fin de ligne unique par garde (# livrable-vide, # livrable-lien, # livrable-borne, # livrable-exclus, # empreinte-tri, # verdict-plafond, # verdict-consommation, # verdict-forme-juge) ciblee par un mutant"
    - "mutant tue par structure ou par verdict, trace assertion, attendu (original), obtenu (mutant), jamais par la duree"

key-files:
  created:
    - plugin/planning-core/scripts/tests/test-cloture-empreintes.sh
  modified:
    - plugin/planning-core/scripts/poser-verdict.sh
    - plugin/planning-core/scripts/planning-hook.sh
    - plugin/planning-core/scripts/recalc-planning.sh
    - plugin/planning-core/scripts/deroger-gate.sh
    - plugin/planning-core/references/templates/cycles/VERDICT.template.md
    - plugin/planning-core/references/modele-cycles.md
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - README.md
    - README.fr.md

key-decisions:
  - "hash_livrables : nom du champ de la seconde empreinte, insere apres hash"
  - "bornes BORNE_FICHIERS_LIVRABLES = 2000 et BORNE_OCTETS_LIVRABLES = 134217728 (128 Mio) ; la borne de fichiers compte les ENTREES parcourues (fichiers, sous-dossiers, liens), pas les seuls fichiers"
  - "exclusions fixes .DS_Store, Thumbs.db, desktop.ini, appliquees au predicat vide ET a l'empreinte (ecart de precision assume par rapport a P46-D-03a)"
  - "code de sortie du plafond : 65 ; jeton de derogation du plafond : PLAFOND (chemin = unite relative au lab)"
  - "refus de pose (64) quand un livrable est absent, vide ou lien, ou quand ecrit: est absent, vide ou invalide (R4 precede R5)"
  - "entree ecrit: egale a . : livrable absent ; nom interne a un dossier non decodable ou a caractere de controle : illisible (texte canonique non ambigu)"

requirements-completed: [CLOT-01, CLOT-03, CLOT-05]

coverage:
  - id: D1
    description: "Predicat livrable_present et empreinte_livrables uniques, en trois copies ast-identiques, lstat par composant, bornes et exclusions"
    requirement: "CLOT-01"
    verification:
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-cloture-empreintes.sh#R-EMP-01, R-EMP-02, R-EMP-03, R-EMP-04"
        status: pass
    human_judgment: false
  - id: D2
    description: "poser-verdict.sh pose hash et hash_livrables sous le verrou du PLAN.md, relus identiques, et refuse la pose d'un livrable absent, vide, lien, d'un ecrit: invalide ou d'une borne depassee, sans fuite de chemin absolu"
    requirement: "CLOT-03"
    verification:
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-cloture-empreintes.sh#R-EMP-05, R-EMP-06, R-EMP-07"
        status: pass
      - kind: integration
        ref: "VF_GATES_SECTIONS=verdict,lota bash plugin/planning-core/scripts/tests/test-planning-gates.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Plafond de 3 tentatives (code 65, constante du code) levable par une derogation nominative PLAFOND a usage unique consommee sous verrou avant l'ecriture"
    requirement: "CLOT-05"
    verification:
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-cloture-empreintes.sh#R-PLAF-01, R-PLAF-02, R-PLAF-03, R-PLAF-04"
        status: pass
    human_judgment: false
  - id: D4
    description: "Forme d'unite .planning/juges/<juge> pour le verdict de canary d'un juge, jumeaux negatifs"
    requirement: "CLOT-05"
    verification:
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-cloture-empreintes.sh#R-JUGE-FORME-01, R-JUGE-FORME-02"
        status: pass
    human_judgment: false
  - id: D5
    description: "Gabarit VERDICT.template.md et section VERDICT.md / commande de verdict de modele-cycles.md a jour (prose de reference)"
    verification: []
    human_judgment: true
    rationale: "Prose de reference : aucun test n'asserte la justesse du texte ; le verificateur de phase la relit."

duration: 77min
completed: 2026-10-03
status: complete
---

# Phase 46 Plan 01: Moteur, pose des verdicts hachés Summary

**Predicat « livrable present » et empreinte composee des livrables en trois copies ast-identiques, VERDICT.md a deux empreintes pose par la seule commande, plafond de 3 tentatives (code 65) levable par derogation PLAFOND a usage unique, et forme d'unite de juge `.planning/juges/<juge>`**

## Performance

- **Duration:** 77 min (debut approximatif 13:49Z, non capture a l'ouverture ; fin 15:06Z)
- **Started:** 2026-10-03T13:49:00Z (approximatif)
- **Completed:** 2026-10-03T15:06:00Z
- **Tasks:** 3
- **Files modified:** 10 (1 cree, 9 modifies)

## Accomplishments

- Un seul predicat `livrable_present` (statuts `present`, `absent`, `lien`, `vide`, `borne`, `illisible`) et une seule `empreinte_livrables`, copies a l'identique dans `poser-verdict.sh`, `planning-hook.sh` et `recalc-planning.sh`, prouvees ast-identiques (13 noms du bloc, 10 du journal de derogation) et memes verdicts sur 17 cas et la meme empreinte (R-EMP-04).
- `poser-verdict.sh` ecrit `hash` et `hash_livrables` (six cles, ordre fixe), calcules sous le verrou du `PLAN.md` et relus par le parseur ; refus 64 d'un livrable absent, vide ou lien, d'un `ecrit:` invalide, d'une borne depassee ; aucun message ne porte de chemin absolu ni « no such file » (R-EMP-05 a 07).
- Plafond de 3 tentatives : 4e tentative en code 65 avec message distinct et `VERDICT.md` octet pour octet inchange ; derogation `deroger-gate.sh --gate=PLAFOND` a usage unique, `consommer` ast-identique a celui du hook, ordre verrou, derogation, consommation, ecriture prouve par l'ast (R-PLAF-01 a 04).
- Forme d'unite `.planning/juges/<juge>` : artefact hache `SORTIE-PIEGEE.md`, pas de `hash_livrables`, plafond applique, toute autre forme refusee (R-JUGE-FORME-01 et 02).
- Dix mutants tues avec trace du rouge (assertion, attendu, obtenu) : MUT-EMP-VIDE, MUT-EMP-LIEN, MUT-EMP-BORNE, MUT-EMP-EXCLUS, MUT-VERDICT-HASH-LIVRABLES, MUT-PLAF, MUT-PLAF-CONSO, MUT-PLAF-ORDRE, MUT-EMP-AST, MUT-JUGE-FORME.

## Task Commits

1. **Task 1 (traceur) : deux empreintes du verdict et predicat livrable present** - `52a6e737` (feat)
2. **Task 2 : plafond de trois tentatives et bloc d'empreinte partage** - `9d1ad334` (feat)
3. **Task 3 : verdict de canary de juge pose par la commande** - `5e33b3f6` (feat)

**Plan metadata:** commit `docs(46-01)` de ce SUMMARY (le suivant dans l'historique).

Tracer verifie de bout en bout avant l'expansion (les trois `<automated>` de la Tache 1 au vert sur l'etat commite), puis expansion.

## Files Created/Modified

- `plugin/planning-core/scripts/poser-verdict.sh` - bloc partage, deux empreintes, refus de pose, plafond et derogation PLAFOND, forme de juge, en-tete et usage.
- `plugin/planning-core/scripts/planning-hook.sh` - bloc partage copie a l'identique (appele par rien dans ce plan : G3 et G4 en 46-05).
- `plugin/planning-core/scripts/recalc-planning.sh` - bloc partage copie a l'identique (R4 en 46-03) ; docstring de `entree_ecrit_valide` alignee.
- `plugin/planning-core/scripts/deroger-gate.sh` - jeton `PLAFOND` (GATES, usage, message de refus, en-tete).
- `plugin/planning-core/scripts/tests/test-cloture-empreintes.sh` - nouvelle suite (R-EMP-01 a 07, R-PLAF-01 a 04, R-JUGE-FORME-01 et 02, dix mutants).
- `plugin/planning-core/scripts/tests/test-planning-gates.sh` - fixtures alignees sur la regle de pose (voir deviations).
- `plugin/planning-core/references/templates/cycles/VERDICT.template.md` - cle `hash_livrables`, prose des deux empreintes.
- `plugin/planning-core/references/modele-cycles.md` - sections `VERDICT.md`, derogation et commande de verdict.
- `README.md`, `README.fr.md` - compteur 104 -> 105 suites.

## Decisions Made

Les decisions de discretion annoncees par le plan sont appliquees telles quelles : champ `hash_livrables`, bornes 2000 et 134217728, exclusions `.DS_Store`/`Thumbs.db`/`desktop.ini` (predicat « vide » et empreinte), code 65, jeton `PLAFOND`, refus de pose sur livrable absent, vide ou lien. Precisions prises a l'execution (renversables) :

- La borne de fichiers compte les **entrees parcourues** (fichiers, sous-dossiers, liens) et non les seuls fichiers : un arbre de dossiers vides imbriques ne contourne plus la borne (T-46-012). Le libelle du refus dit « fichiers » et nomme `BORNE_FICHIERS_LIVRABLES`.
- `hashlib` est importe **dans** les fonctions du bloc partage (copie identique dans les trois scripts, aucun cout d'import ajoute au hook sur les chemins existants).
- Une entree `ecrit:` egale a `.` est `absent` (la racine du lab n'est pas un livrable) ; un nom interne a un dossier non decodable en UTF-8 ou portant un caractere de controle rend `illisible` (le texte canonique reste non ambigu).
- Une entree `ecrit:` absolue ou en `~` n'est jamais reprise dans le message de refus (pas de chemin absolu hors du lab, P46-D-10).
- La consommation de la derogation PLAFOND vient apres la verification du texte du verdict et immediatement avant `ecrire_atomique` (une consommation perdue par un echec d'ecriture est le cas fail-closed ecrit dans l'en-tete).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixtures de test-planning-gates.sh alignees sur la regle de pose**
- **Found during:** Task 1
- **Issue:** la nouvelle regle de pose refuse un livrable absent ; trois fixtures n'avaient pas de livrable (R-VERDICT-07 : `ecrit: a`, R-IMB-02 : `ecrit: livrables` sans le dossier) et R-VERDICT-01 attendait cinq cles de frontmatter.
- **Fix:** `ecrit: livrables/rapport.md` dans R-VERDICT-07 (deux boucles), `livrables/rapport.md` non vide ajoute a `lab_imbrique`, R-VERDICT-01 attend les six cles et verifie `hash_livrables` (64 hexadecimaux). Aucun cas retire ni affaibli ; le mutant VERDICT-FORME-UNITE reste tue.
- **Files modified:** plugin/planning-core/scripts/tests/test-planning-gates.sh
- **Verification:** `VF_GATES_SECTIONS=verdict,lota` : 74 OK, 0 KO
- **Committed in:** 52a6e737

**2. [Rule 1 - Bug] Docstring de `entree_ecrit_valide` du recalcul differente de celle du hook**
- **Found during:** Task 2 (R-EMP-04 rouge sur la comparaison reelle)
- **Issue:** les arbres ast, docstring comprise, differaient entre `planning-hook.sh` et `recalc-planning.sh` (docstring seule), alors que le plan exige trois copies identiques.
- **Fix:** docstring du recalcul alignee sur celle du hook (corps inchange).
- **Files modified:** plugin/planning-core/scripts/recalc-planning.sh
- **Verification:** R-EMP-04 vert ; `test-recalc-planning.sh` : 358 OK, 0 KO
- **Committed in:** 9d1ad334

**3. [Rule 2 - Missing critical] Message d'erreur d'E/S de poser-verdict.sh sans chemin absolu**
- **Found during:** Task 1 (P46-D-10, T-46-015)
- **Issue:** le gestionnaire `OSError` de `main()` imprimait `str(exc)`, qui contient le chemin absolu et « No such file or directory ».
- **Fix:** message neutre `échec de lecture ou d'écriture (<type>) : aucun verdict posé`, code 1 inchange.
- **Files modified:** plugin/planning-core/scripts/poser-verdict.sh
- **Verification:** R-EMP-07 vert
- **Committed in:** 52a6e737

---

**Total deviations:** 3 auto-fixed (1 blocking, 1 bug, 1 missing critical)
**Impact on plan:** necessaires a la correction et a la securite, sans extension de perimetre.

### Adaptations de protocole (mandat)

- Le garde d'isolation du poste a refuse l'ecriture du registre de base `gsd-plan-head-before-46-01` dans le repertoire git partage (« Edit the worktree copy of this file instead of the shared-checkout path », puis « this command names git in a form too complex to verify that it stays inside the worktree »). Il n'a pas ete contourne : la base du plan (`164d7537b3f648d576aaf13e555905a9ec4b1cab`, HEAD au demarrage) est inscrite dans `plan_head_before` et `commits: 3` est mesure par `git rev-list --count` depuis cette base.
- L'assertion « branche `agent-*` » de la liste d'autorisation worktree n'a pas ete appliquee : le mandat designe la branche de mission `gouvernance/phase-46-execution` du worktree `gouvernance-46` ; la racine pinee a ete verifiee avant chaque ecriture et chaque commit, la branche n'est pas une branche protegee.
- Deux lancements longs (`verdict,lota` et `table,parseur,registre,jeton,derog,mutants,lota`) ont depasse les 600 s sous une charge machine d'environ 30 : le harnais les a bascules en arriere-plan, sans choix de ma part ; les deux ont fini en code 0 (74 OK et 155 OK, 0 KO).

## Issues Encountered

- Mutant EXCLUS : le remplacement `pass` d'une ligne `if` laissait un `continue` isole (SyntaxError) ; remplace par `if False:`.
- Rouge d'une suite hors perimetre : aucun. `test-planning-hook-registered.sh` (R-DOUTE-03, rouge temporel connu a la base) n'est pas nomme par ce plan et n'a pas ete rejoue.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Resultats des verifications automatisees (code de sortie)

| Verification | Code |
|---|---|
| T1 `test-cloture-empreintes.sh` (R-EMP-01 a 03, 05 a 07, cinq mutants, DUREE < 600) | 0 (11 OK, 0 KO) |
| T1 `VF_GATES_SECTIONS=verdict,lota test-planning-gates.sh` | 0 (74 OK, 0 KO) |
| T1 `scripts/check-version-sync.sh` | 0 |
| T2 `test-cloture-empreintes.sh` (R-EMP-04, R-PLAF-01 a 04, quatre mutants) | 0 (20 OK, 0 KO) |
| T2 `test-recalc-planning.sh` | 0 (358 OK, 0 KO) |
| T2 `VF_GATES_SECTIONS=table,parseur,registre,jeton,derog,mutants,lota test-planning-gates.sh` | 0 (155 OK, 0 KO) |
| T3 `test-cloture-empreintes.sh` entiere (R-JUGE-FORME, MUT-JUGE-FORME, DUREE = 10 s) | 0 (23 OK, 0 KO) |
| T3 `VF_GATES_SECTIONS=verdict,lota,reference test-planning-gates.sh` | 0 (92 OK, 0 KO) |
| T3 `45-CONTROLE-MARQUEUR.sh --base=247194c7 -- plugin/planning-core/scripts plugin/planning-core/hooks` | 0 (`MARQUEUR-BILAN commits=3 sans-marqueur=0`) |
| Plan, sections restantes de `test-planning-gates.sh` (g2 a banc) | 0 (283 OK, 0 KO) |
| `scripts/check-machine-paths.sh`, `scripts/check-version-sync.sh`, `check-planning-consumers-registered.sh` | 0 |

Critères d'acceptation rejoués : `awk '/hash_livrables/'` du gabarit (au moins une ligne), `awk '/^PLAFOND_TENTATIVES = 3/'` (une ligne), `awk '/PLAFOND/'` de `deroger-gate.sh` (5 lignes), `awk '/juges/'` et `awk '/65/ && /plafond/'` de `modele-cycles.md` (au moins une ligne chacun).

## Next Phase Readiness

- Le modele de la pose est en place : les plans 46-03 (R4, empreintes et `à clore` au recalcul), 46-05 (G3, G4) et 46-09 (contrat de la sortie piegee) lisent `livrable_present`, `empreinte_livrables`, `hash_livrables`, le code 65 et la forme `.planning/juges/<juge>`.
- Rien n'est arme : aucun gate ne refuse une ecriture par outil a ce stade.

---
*Phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s*
*Completed: 2026-10-03*

## Self-Check: PASSED

- Fichier cree present : `plugin/planning-core/scripts/tests/test-cloture-empreintes.sh` ; fichiers modifies presents.
- Commits presents : `52a6e737`, `9d1ad334`, `5e33b3f6` (`git log --all --grep="46-01"`).
- Aucune modification de STATE.md, ROADMAP.md ni REQUIREMENTS.md ; fichier non suivi `.planning/missions/2026-10-03-gouvernance-46-exec.dag.json` non stage.
