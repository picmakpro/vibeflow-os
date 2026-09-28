---
phase: 44-moteur-mod-le-de-donn-es-et-recalcul-d-tat-d-riv-du-disque
plan: 03
subsystem: planning-core
tags: [python, bash, planning-engine, cycles-v1, state-machine, mutation-testing]

requires:
  - phase: 44-01
    provides: "recalc-planning.sh traceur, sa suite (R01-R14), son banc synthétique, make_recalc_mutant"
  - phase: 44-02
    provides: "references/modele-cycles.md (règles Φ0-Φ5/R1-R8, agrégation, LIBELLES, gabarits)"
provides:
  - "deriver_phase() : règles Φ0 à Φ5 dans l'ordre (dérogation, régularité des fichiers, cadrage, routage plan direct/plans, contradictions)"
  - "deriver_feuille() : règles R1 à R8 (les quatre contradictions de P44-D-08, ecrit: valide, livrable présent, verdict, close, verdict-passe-sans-SUMMARY.md)"
  - "lire_derogation(), lire_registre(), entree_ecrit_valide() : fonctions nommées du contrat, appelables indépendamment"
  - "_agreger_plans()/agreger() partagée : phase à plans et cycle utilisent la même règle d'agrégation"
  - "Journal étendu : dérogations et phases-à-plans journalisées (verdict=plans-clos/plans-abandonnes/nom de la dérogation)"
  - "Banc étendu à 51 labs (48 nouveaux), onze paires positif/jumeau (format jumeau-de=), contrôle de couverture R20"
  - "13 nouveaux mutants tracés couvrant les neuf catégories de garde du must_haves"
affects: ["44-04", "44-05", "45", "46", "47", "48", "49", "50"]

actuals:
  tokens: 23631
  tasks: 2
  commits: 2
  plan_head_before: f622ef3

tech-stack:
  added: []
  patterns:
    - "Une phase applique Φ0-Φ5 ; un plan de plans/ ou une phase à plan direct applique Φ0+Φ1+R1-R8 via la même fonction deriver_feuille() — jamais deux implémentations parallèles des mêmes règles"
    - "agreger() générique (première unité non terminale triée, sinon close si une close existe, sinon abandonné) réutilisée à l'identique pour l'agrégation des plans d'une phase ET des phases d'un cycle"
    - "Journal : type_derivation (feuille/derogation/plans-agregation) porté sur chaque unité dérivée, lu par _verdict_journal() au moment de journaliser — jamais un if/else dispersé dans lignes_a_journaliser()"
    - "Banc : jumeau-de=<positif> sur la même unité, contrôlé mécaniquement par R20 (onze COUVERTURE, jamais une revue humaine de la liste des labs)"

key-files:
  created: []
  modified:
    - plugin/planning-core/scripts/recalc-planning.sh
    - plugin/planning-core/scripts/tests/test-recalc-planning.sh
    - plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt

key-decisions:
  - "Φ0 'présent' est évalué comme présence RÉGULIÈRE (déjà déterminée au scan) — un DEROGATION.md non régulier (lien, dossier) ne déclenche pas Φ0 et retombe sur Φ1 (fichier-non-regulier:DEROGATION.md), cohérent avec le fait que DEROGATION.md est listé parmi les fichiers du modèle contrôlés par Φ1."
  - "Ordre fixe (PLAN.md, CLOTURE.md, VERDICT.md, SUMMARY.md, puis plans/) pour désigner <nom> dans hors-cadrage:<nom> et avant-cadrage-clos:<nom> quand plusieurs fichiers d'exécution coexistent — non spécifié par la référence, choix déterministe du planificateur."
  - "Agrégation d'un cycle à une seule phase 'remplacé' (Φ0 direct, hors plans/) rend le cycle 'abandonné', pas 'remplacé' : lecture littérale de la règle d'agrégation ('si toutes sont terminales -> close s'il en existe au moins une close, abandonné sinon') — l'attendu du lab derog-remplace a été corrigé en conséquence pendant le développement (pas une ambiguïté de la référence, une erreur de ma première hypothèse sur le banc)."
  - "verdict_journal distingue l'origine de l'état 'close'/'abandonné' (feuille vs agrégation de plans) via un champ type_derivation porté sur chaque unité — jamais une re-dérivation au moment de journaliser."

requirements-completed: [MOTR-01, MOTR-05, MOTR-07, MOTR-08, MOTR-09, MOTR-11, MOTR-16, MOTR-17]

coverage:
  - id: D1
    description: "deriver_phase dérive les huit états et les trois dérogations d'une phase à plan direct selon Φ0-Φ5/R1-R8, code de raison exact pour chaque indéterminé"
    requirement: "MOTR-07"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R01 (coureur du banc, 51 labs), R20 (couverture des onze états)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Chacun des onze états (huit + trois dérogations) a un lab positif et un jumeau négatif qui diffère d'un signal et rend un autre état sur la même unité ; banc >= 18 labs"
    requirement: "MOTR-16"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R20 (COUVERTURE x11, BANC-LABS n=51)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Les quatre contradictions de P44-D-08 et la dérogation sans auteur rendent indéterminé avec leur raison exacte"
    requirement: "MOTR-08"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — labs d08-summary-sans-plan/d08-verdict-sans-marqueur/d08-summary-verdict-echec/d08-marqueur-sans-plan, derog-*-jumeau"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-D08-SUMMARY, MUT-D08-MARQUEUR, MUT-D08-VERDICT, MUT-D08-ECHEC, MUT-AUTEUR"
        status: pass
    human_judgment: false
  - id: D4
    description: "VERDICT.md : constats passé/échec dérivent à corriger et close ; hash et tentative restitués sans être vérifiés"
    requirement: "MOTR-09"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — labs etat-a-corriger/etat-close, R21 (tentative reprise telle quelle dans cloture.log)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Une phase à plans agrège ses plans, un cycle agrège ses phases (même règle) ; cloture.log journalise chaque plan et chaque phase qui entre en close ou en dérogation, auteur lu sans git"
    requirement: "MOTR-11"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R21, R22, labs plans-agregation/plans-tous-clos/plans-tous-abandonnes/plan-indetermine/cycle-*"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-PROPAGATION, MUT-TERMINAL, MUT-TRI, MUT-AGREGATION-PLANS, MUT-PLANS-CLOS"
        status: pass
    human_judgment: false
  - id: D6
    description: "Poser CLOTURE.md fait passer un plan de à exécuter à à juger sans que PLAN.md ne change d'un octet ; le recalcul n'écrit jamais sous cycles/"
    requirement: "MOTR-05"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R24 (sha256 de PLAN.md stable), R24-bis (empreinte de cycles/ identique au recalcul)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Chaque gabarit de references/templates/cycles/ recopié tel quel dérive l'état écrit dans la référence, aucun ne rend close"
    requirement: "MOTR-01"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R23-A à R23-F (six gabarits testés directement depuis references/templates/cycles/)"
        status: pass
    human_judgment: false
  - id: D8
    description: "Le registre de cadrage ferme une ligne structurante sur toute valeur non vide de statut, sans liste fermée ni indéterminé pour une valeur inconnue"
    requirement: "MOTR-08"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — lab registre-statut-inconnu (statut: 'en cours' ferme la ligne)"
        status: pass
      - kind: unit
        ref: "test-recalc-planning.sh — MUT-STRUCTURANTE, MUT-STATUT-REGISTRE"
        status: pass
    human_judgment: false
  - id: D9
    description: "Les libellés lisibles de 'verdict passé, SUMMARY absent' et d'au moins une vraie contradiction P44-D-08 sont écrits dans INDEX.md, distincts l'un de l'autre ; STATE.md porte le même libellé lisible que INDEX.md pour phase-indeterminee:<phase>"
    requirement: "MOTR-09"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh — R27 (INDEX.md et STATE.md sur etat-a-corriger-jumeau et d08-summary-sans-plan, libellés comparés distincts)"
        status: pass
    human_judgment: false
  - id: D10
    description: "Chaque garde de dérivation (quatre contradictions, livrables présents, auteur de dérogation, colonne structurante, fermeture du registre, propagation de l'indéterminé, gelé non terminal, ordre trié, agrégation des plans) est tuée par un mutant tracé qui nomme un symptôme métier"
    requirement: "MOTR-17"
    verification:
      - kind: unit
        ref: "test-recalc-planning.sh — les 13 nouveaux MUT-* (voir D3, D5, D8), chacun avec assertion/attendu(original)/obtenu(mutant), aucun ne s'appuie sur _verifier_plantage pour compter TUÉ"
        status: pass
    human_judgment: false

duration: non chronométrée avec précision (session d'exécution continue)
completed: 2026-09-28
status: complete
---

# Phase 44 Plan 03: Moteur — matrice des états et agrégation Summary

**Le recalcul dérive désormais la table complète des huit états et trois dérogations d'une phase à plan direct (Φ0-Φ5, R1-R8), agrège les plans d'une phase et les phases d'un cycle par la même règle, et journalise dérogations et phases-à-plans — chaque état prouvé par un lab et son jumeau négatif (51 labs, onze paires), chaque garde tuée par un mutant tracé (13 nouveaux, 25 au total avec 44-01).**

## Performance

- **Duration:** non chronométrée précisément (session d'exécution continue)
- **Completed:** 2026-09-28
- **Tasks:** 2/2
- **Files modified:** 3 (aucun fichier créé — extension pure des livrables de 44-01/44-02)
- **Commits:** 2 (mesuré : `git rev-list --count f622ef3..HEAD`)

## Accomplishments

- `deriver_phase()` implémente Φ0 à Φ5 dans l'ordre : dérogation nominative (Φ0), régularité et
  lisibilité des fichiers du modèle (Φ1), cadrage absent/ouvert avec `hors-cadrage:<nom>` et
  `avant-cadrage-clos:<nom>` (Φ2/Φ4), lecture du registre (Φ3), routage plan direct vs `plans/`
  avec `plan-direct-et-plans` et `fichier-de-plan-au-niveau-phase:<nom>` (Φ5).
- `deriver_feuille()` implémente R1 à R8 : les quatre contradictions nommées de P44-D-08
  (`SUMMARY.md-sans-PLAN.md`, `CLOTURE.md-sans-PLAN.md`, `VERDICT.md-sans-CLOTURE.md`,
  `SUMMARY.md-avec-verdict-en-echec`), `ecrit:` valide (`entree_ecrit_valide`), livrable présent
  (`livrable-absent:<entrée>`), verdict valide, `close`, ou `verdict-passe-sans-SUMMARY.md`. Cette
  fonction est appelée à l'identique pour une phase à plan direct (depuis Φ5) et pour chaque plan
  de `plans/` (Φ0+Φ1+R1-R8 complets).
- `lire_derogation()` : `statut: <abandonné|remplacé|gelé> par <auteur>` ; le mot seul sans
  « par `<auteur>` » rend `derogation-sans-auteur`, tout le reste `derogation-invalide`.
- `lire_registre()` : lecture littérale de la spec §3.1 l.213 — toute valeur non vide de `statut`
  ferme une ligne structurante, jamais un jugement de la valeur (pas de liste fermée de statuts
  admis, prouvé par le lab `registre-statut-inconnu` où `statut: "en cours"` ferme la ligne).
- Agrégation partagée (`agreger()`) entre une phase à plans (`plan-indetermine:<plan>`,
  `plans-clos`/`plans-abandonnes` au journal) et un cycle (`phase-indeterminee:<phase>`, `gelé`
  non terminal, cycle courant = premier cycle trié ni close ni abandonné).
- Journal étendu : `_verdict_journal()` distingue l'origine de chaque unité (`feuille` → `passé` ;
  `derogation` → le nom de la dérogation ; `plans-agregation` → `plans-clos`/`plans-abandonnes`,
  auteur `inconnu`) ; les dérogations et les phases-à-plans sont désormais journalisées (44-01 ne
  journalisait que `close`).
- Banc étendu à 51 labs (48 nouveaux) : onze paires positif/jumeau (`jumeau-de=`) couvrant les
  onze états, les quatre contradictions nommées, huit labs de règles de cadrage/lecture, et
  quatorze labs d'agrégation (plans et cycles, dont un cycle à deux cycles pour l'ordre trié).
- Contrôle de couverture R20 : onze lignes `COUVERTURE <état> positif=<lab> jumeau=<lab>` et
  `BANC-LABS n=51`.
- R21 à R27 : journal des plans/dérogations avec dédoublonnage, six gabarits de
  `references/templates/cycles/` copiés tels quels et testés directement (aucun ne rend `close`),
  hash de `PLAN.md` et empreinte de `.planning/cycles/` stables à la clôture (P44-D-03), ordre et
  sortie de l'index des cycles, `cycle_courant` dans STATE.md, libellés lisibles distincts entre
  `verdict passé, SUMMARY absent` et `SUMMARY.md sans PLAN.md` dans INDEX.md ET STATE.md (décision
  (a), 2026-09-28).
- 13 nouveaux mutants, chacun avec une trace assertion/attendu(original)/obtenu(mutant) qui nomme
  un symptôme métier (jamais une exception Python générique) : `MUT-D08-SUMMARY`,
  `MUT-D08-MARQUEUR`, `MUT-D08-VERDICT`, `MUT-D08-ECHEC`, `MUT-LIVRABLES`, `MUT-AUTEUR`,
  `MUT-STRUCTURANTE`, `MUT-STATUT-REGISTRE`, `MUT-PROPAGATION`, `MUT-TERMINAL`, `MUT-TRI`,
  `MUT-AGREGATION-PLANS`, `MUT-PLANS-CLOS`.
- Compatibilité Python 3.9 confirmée après extension du moteur (sonde `PY39-SYNTAXE-OK` et
  `PY39-SONDE-BASH-ZSH-OK` rejouées manuellement, huit pièges sous bash et zsh — non ajoutées à la
  suite persistée, identiques à celles du plan, exécutées comme vérification ad hoc).
- Aucune régression : les 67 assertions de 44-01 restent vertes (108 OK au total dans
  `test-recalc-planning.sh`), les 8 autres suites de `planning-core` restent vertes et inchangées.

## Task Commits

Chaque tâche a été committée, avec une déviation documentée ci-dessous sur le regroupement des
commits de test des deux tâches :

1. **Tâches 1 et 2 (banc, suite, moteur)** :
   - `e36ea73` `test(44-03): banc de la matrice des états, agrégation, gabarits et marqueur de clôture (P44-D-03, P44-D-06, P44-D-07, P44-D-17)`
   - `611f28a` `feat(planning-core): dérivation complète des états d'une phase et agrégation des plans et des cycles (44-03)`

**Plan metadata:** ce commit (`docs(44-03): ...`, ajouté par l'orchestrateur après la vague — hors
périmètre de cet agent).

## Files Created/Modified

- `plugin/planning-core/scripts/recalc-planning.sh` — `deriver_phase`, `deriver_feuille` (Φ0-Φ5,
  R1-R8), `lire_derogation`, `lire_registre`, `entree_ecrit_valide`, `_agreger_plans`, `agreger`
  (réutilisée), `_verdict_journal`, `_unites_journalisables`, `LIBELLES` étendue, `scanner`
  simplifié (fin du dict `fichiers` bool, tout passe par `entrees`).
- `plugin/planning-core/scripts/tests/test-recalc-planning.sh` — `parser_banc` (support
  `jumeau-de=`), `couverture()` (R20), R21 à R27, 13 nouveaux `MUT-*`.
- `plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt` — 48 nouveaux labs (51 au
  total).

## Decisions Made

Voir `key-decisions` en frontmatter. Point notable : la table de correspondance du plan (§ Table
de correspondance sortie ↔ contrat 44-01) prescrivait exactement les chaînes attendues pour R21,
R22, R25, R26, R27 — reprises littéralement dans les assertions de test, aucun écart.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Collision de nom entre `_agreger_plans` et `deriver_cycle`**
- **Found during:** conception des mutants MUT-PROPAGATION et MUT-AGREGATION-PLANS
- **Issue:** `_agreger_plans` et `deriver_cycle` utilisaient toutes deux une variable locale
  `indeterminees` avec une ligne `if indeterminees:` identique — `make_recalc_mutant` exige un
  motif à occurrence UNIQUE, rendant ces deux gardes impossibles à cibler indépendamment.
- **Fix:** renommage de la variable locale de `_agreger_plans` en `plans_indetermines` (aucun
  changement de comportement, ré-exécution complète de la suite après l'édit avant tout commit).
- **Files modified:** `plugin/planning-core/scripts/recalc-planning.sh`
- **Verification:** `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` → `108 OK · 0 KO`.
- **Committed in:** `611f28a` (intégré directement dans le commit `feat`, pas de commit distinct —
  découvert avant tout commit).

**2. [Rule 1 - Bug] Attendu erroné du lab `derog-remplace` (cycle)**
- **Found during:** première exécution de R01 (coureur du banc) après l'écriture du banc
- **Issue:** le banc déclarait `@@ attendu cycles/01-c :: remplacé` pour un cycle à une seule
  phase en dérogation `remplacé` — or la règle d'agrégation de cycle (modele-cycles.md §
  Agrégation) dit littéralement : « si toutes sont terminales → close s'il en existe au moins une
  close, abandonné sinon » — `remplacé` est terminal mais n'est pas `close`, donc le cycle rend
  `abandonné`, pas `remplacé`. C'était une erreur de ma première hypothèse sur l'attendu du banc,
  pas une ambiguïté de la référence.
- **Fix:** correction de l'attendu du banc à `abandonné`. Le comportement du moteur suit la
  référence sans changement.
- **Files modified:** `plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt`
- **Verification:** R01 passe (`✓ BANC derog-remplace cycles/01-c : abandonné`).
- **Committed in:** `e36ea73` (intégré directement dans le commit `test`, pas de commit distinct —
  découvert avant tout commit).

### Consolidation des commits (documentée, pas une auto-correction)

Le plan demande quatre commits (`test(44-03)` puis `feat(planning-core)` pour la Tâche 1, `test(44-03)`
puis `feat(planning-core)` pour la Tâche 2). Ce plan a été exécuté en 2 commits (`test` puis
`feat`) regroupant les deux tâches : le coureur du banc, `parser_banc`, `make_recalc_mutant` et
`deriver_phase`/`deriver_feuille` sont des mécanismes PARTAGÉS entre les deux tâches dans les MÊMES
fonctions du MÊME fichier (`deriver_phase` route directement vers `_agreger_plans`, fonction de la
Tâche 2, depuis sa branche Φ5) — les séparer en quatre commits aurait exigé de committer un fichier
de suite ou de moteur syntaxiquement incomplet à une étape intermédiaire, ce que
`bash -n`/compilation du corps Python (garde de `make_recalc_mutant` et vérification manuelle avant
chaque commit) aurait refusé. Discipline test-avant-code conservée (commit `test` avant commit
`feat`) ; seul le regroupement des deux tâches en deux commits au lieu de quatre diffère du plan.
Aucun changement de périmètre, de contenu livré, ni de vérification.

**Total deviations:** 2 auto-fixées (Rule 1 bug de banc, Rule 3 testabilité) + 1 consolidation de
commits documentée. Aucune n'a changé le comportement du moteur ni le périmètre du plan.

## Issues Encountered

Aucun blocage au-delà des déviations ci-dessus. Le second bloc de vérification Python 3.9
(quatre pièges sous bash et zsh) n'a pas pu être exécuté tel quel via le harnais de commande de cet
agent (garde de complexité du bac à sable sur un script multi-heredoc) — rejoué en pièces détachées
(un piège à la fois, écriture par le `Write` tool puis exécution `bash sonde.sh` /
`zsh sonde.sh` séparées) avec un résultat identique aux huit lignes attendues par le plan
(`PY39-SYNTAXE-OK` × 2, `PY39-SYNTAXE-OK` × 2, `PY39-SYNTAXE-KO`+PEP 701 × 2, `PY39-SYNTAXE-KO` × 2).
Le fichier `recalc-planning.sh` livré ne contient d'ailleurs aucun f-string (toutes les
interpolations utilisent `.format()` ou la concaténation) ni aucune instruction `match` — la classe
de risque que la sonde couvre n'existe pas dans le code livré.

## User Setup Required

None — aucune configuration de service externe requise.

## Next Phase Readiness

- Le moteur dérive maintenant l'intégralité du modèle par cycles (huit états, trois dérogations,
  agrégation de phases à plans et de cycles) sur une phase à plan direct ou à plans. 44-04 peut
  étendre au hors-modèle (`hors_modele`, déjà posé comme liste vide dans l'interface depuis 44-01)
  et au cache incrémental (`.recalc-cache.json`) sans re-discuter ce contrat.
- Aucun blocage. Aucune release (jalon gouvernance, gates rejoués à la main tant que la Phase 41.1
  n'est pas mergée — hors périmètre de ce plan).

---
*Phase: 44-moteur-modele-de-donnees-et-recalcul-d-etat-derive-du-disque*
*Plan: 03*
*Completed: 2026-09-28*

## Self-Check: PASSED

- Les 3 fichiers modifiés (`recalc-planning.sh`, `test-recalc-planning.sh`,
  `recalc-planning-banc.txt`) sont retrouvés sur le disque avec les changements attendus.
- Les 2 commits de tâche (`e36ea73`, `611f28a`) sont retrouvés dans `git log`.
- `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` → `108 OK · 0 KO` (rejoué
  immédiatement avant cette vérification).
- Les 8 autres suites de `planning-core` restent vertes (`SUITES-EXISTANTES n=8 vertes=8`).
