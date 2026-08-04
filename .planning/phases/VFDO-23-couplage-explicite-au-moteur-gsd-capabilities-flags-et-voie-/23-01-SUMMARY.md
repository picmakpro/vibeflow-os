---
phase: VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-
plan: 01
subsystem: dev-orchestrator
tags: [gsd-core, checkpoint, gate, mission-contracts, vf-coder, vf-dev-manager, test-discriminance]

# Dependency graph
requires:
  - phase: 20-mission-flow-pattern-e
    provides: mission-flow.md §Pattern E (étage revue de premier rang)
  - phase: 22-docs-flow
    provides: docs-flow.md (doctrine de sortie documentaire)
provides:
  - Champ optionnel gate (contrat de checkpoint amont) dans le bloc typé vf-coder, mapping
    unique gate="blocking-human" OU précondition non satisfaite ⇒ statut human_needed
  - Geste 5 non négociable de vf-dev-manager: reset de workflow._auto_chain_active à false
    avant tout dispatch, fermé par gate contre sa réintroduction sur les briques Plan/Exécution
  - Champ optionnel reprise{plan_id, checkpoint, gate, attendu} sur statut human_needed, garde
    anti-duplication ADR-030 contre la reproduction du contrat interne de l'exécuteur amont
  - Halte de nœud (jamais de mission) nommée explicitement ; vf-dev-manager comme unique
    répondant aux attentes humaines du moteur (vf-coder escalade, jamais n'auto-répond)
  - T24/T25/T26 dans test-dev-orchestrator.sh, chacun à discriminance prouvée par mutation
affects: [23-03-doctrine-flags, 23-05-voie-unique-continuation, 23-06-etage-revue, 23-07-budget-partage]

# Actuals (#2632) — pairs with the plan's estimate to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
actuals:
  tokens: 3321
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Contrat de checkpoint amont (gate + reprise) recopié verbatim depuis gsd-core, jamais recalculé côté VibeFlow"
    - "Assertion discriminante par mutation dans une copie mktemp -d (jamais sur le fichier réel du dépôt), trap EXIT cumulatif pour éviter le clobbering entre blocs de test successifs"
    - "Exclusion documentée de scripts/tests/ dans tout balayage de fixture — sinon le gate se détecte lui-même"

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/references/mission-contracts.md
    - plugin/dev-orchestrator/agents/vf-coder.md
    - plugin/dev-orchestrator/agents/vf-dev-manager.md
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh

key-decisions:
  - "D-01 : une seule règle de mapping (gate=\"blocking-human\" OU précondition non satisfaite ⇒ human_needed) plutôt que deux chemins parallèles — un refus d'auto-approbation amont est un refus, quel qu'en soit le motif."
  - "D-02 : le reset du flag d'enchaînement est best-effort (consigné au rapport si gsd_run ne se résout pas, jamais bloquant) — cohérent avec le patron déjà appliqué au §Seuil de bascule."
  - "D-03 (révisée en cadrage) : le minimum de reprise porte EXACTEMENT 4 sous-champs, jamais la table des tâches déjà exécutées — ADR-030 interdit de dupliquer le contrat interne de l'exécuteur amont."
  - "D-04bis : vf-coder n'auto-répond JAMAIS à une attente humaine (ni checkpoint amont, ni garde-fou de reprise sûre) — c'est vf-dev-manager, et lui seul, qui pose la question et redispatche."

patterns-established:
  - "Mutation prouvée en DEUX temps par tâche : (a) une assertion mktemp -d interne au bloc de test, rejouée à chaque run de la suite ; (b) une injection/retrait réel et éphémère sur le fichier du dépôt, exécuté une fois pendant le plan et consigné ici avec commande + compteur avant/après, puis restauré et re-vérifié à 0 KO."

requirements-completed: [GSDC-01, GSDC-02]

coverage:
  - id: D1
    description: "Le champ gate traverse référence → vf-coder → vf-dev-manager avec mapping unique vers human_needed"
    requirement: "GSDC-01"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T24"
        status: pass
    human_judgment: false
  - id: D2
    description: "workflow._auto_chain_active est remis à false au démarrage de mission et fermé par gate sur les briques Plan/Exécution"
    requirement: "GSDC-02"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T25"
        status: pass
    human_judgment: false
  - id: D3
    description: "Minimum de reprise (4 sous-champs), halte de nœud, réponse par le manager, garde anti-duplication ADR-030"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T26"
        status: pass
    human_judgment: false

# Metrics
duration: ~35min (estimation — horodatage de démarrage non capturé, exécution en une passe continue)
completed: 2026-08-01
status: complete
---

# Phase 23 Plan 01: Contrat de checkpoint amont (gate) Summary

**Le champ `gate` de `gsd-core` traverse désormais référence → `vf-coder` → `vf-dev-manager` avec
une règle unique vers `human_needed`, le flag `_auto_chain_active` est désarmé au démarrage de
mission et fermé par gate, et un minimum de reprise à 4 sous-champs remplace toute tentation de
dupliquer le contrat interne de l'exécuteur amont — les trois garanties verrouillées par T24/T25/T26,
chacune à discriminance prouvée par mutation réelle, pas seulement lue.**

## Performance

- **Duration:** ~35min (estimation)
- **Tasks:** 3/3
- **Files modified:** 4 (mission-contracts.md, vf-coder.md, vf-dev-manager.md, test-dev-orchestrator.sh)
- **Suite finale :** `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` → `84 OK / 0 KO / 0 SKIP`

## Accomplissements

- **Tâche 1 (D-01)** : section `## Contrat de checkpoint amont` créée dans `mission-contracts.md`
  (champ optionnel `gate`, règle unique de mapping vers `human_needed`) ; `vf-coder.md` §Retour
  et `vf-dev-manager.md` §Contrôle de flux nomment tous deux `gate="blocking-human"` comme
  déclencheur nommé de l'escalade. T24 verrouille la chaîne (assertions A/B/C + D discriminante
  par mutation).
- **Tâche 2 (D-02)** : geste 5 non négociable dans `vf-dev-manager.md` §Discipline de pilotage —
  `gsd_run config-set workflow._auto_chain_active false` avant tout dispatch, best-effort,
  renvoyant à la cascade `mission-contracts.md` §Seuil de bascule (DRY, aucune recopie de
  `RUNTIME_DIR`). T25 ferme la réintroduction du mode d'enchaînement sur les briques Plan/Exécution
  (licite uniquement sur la brique Cadrage, ligne 27 de `vf-coder.md`).
- **Tâche 3 (D-03, D-04, D-04bis)** : la section « Contrat de checkpoint amont » de
  `mission-contracts.md` s'étend du champ `reprise{plan_id, checkpoint, gate, attendu}` — rien
  d'autre, motif ADR-030 explicite — et d'un constat de continuation minimal. `vf-coder.md` §Retour
  porte la règle « attente humaine ⇒ escalade, jamais auto-répondue ». `vf-dev-manager.md` nomme
  explicitement le « halte de nœud, jamais de mission » et se désigne comme l'unique répondant aux
  attentes humaines du moteur. T26 verrouille les 4 sous-champs + une garde anti-duplication
  NÉGATIVE (assertion D) prouvée par mutation (assertion E).

## Task Commits

Chaque tâche committée atomiquement :

1. **Tâche 1 : le champ `gate` traverse la chaîne de bout en bout (D-01)** — `e9dc934` (feat, tracer/tdd)
2. **Tâche 2 : le flag d'enchaînement autonome est désarmé au démarrage de mission et fermé par gate (D-02)** — `f302419` (feat, tdd)
3. **Tâche 3 : minimum de reprise, halte de nœud, et qui répond aux attentes humaines (D-03, D-04, D-04bis)** — `8d5661a` (feat, tdd)

**SUMMARY :** ce commit (à suivre)

_Note : plan `type: execute` (pas `type: tdd` au niveau plan) — chaque tâche porte `tdd="true"`
mais l'action a construit référence/producteur/consommateur/gate en un seul geste vertical par
tâche (patron tracer explicite en tâche 1), plutôt qu'un cycle RED/GREEN/REFACTOR séparé par
commits distincts. Aucun gate TDD de plan n'était actif (`MVP_MODE`/`TDD_MODE` non positionnés
par l'orchestrateur pour cette exécution)._

## Files Created/Modified

- `plugin/dev-orchestrator/references/mission-contracts.md` — section `## Contrat de checkpoint
  amont (gsd-core 1.9.0)` : champ `gate`, règle unique de mapping, champ `reprise` (4 sous-champs),
  constat de continuation. +31 lignes net (274 lignes finales).
- `plugin/dev-orchestrator/agents/vf-coder.md` — §Retour : paragraphes `gate` et `reprise`, patron
  du paragraphe `estimate:`/`actuals:` déjà écrit. +12 lignes net (86 lignes finales, largement
  sous le plafond ADR-029).
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` — geste 5 (Discipline de pilotage), mention
  `gate="blocking-human"` + « halte de nœud, jamais de mission » + réponse par le manager
  (Contrôle de flux). +8 lignes net (**244 lignes finales** — plafond ADR-029 = 250, **6 lignes de
  marge restante**).
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — blocs `T24`, `T25`, `T26`, +
  correction du trap `EXIT` (cumulatif sur `T24_TMPDIR`/`T25_TMPDIR`/`T26_TMPDIR` pour éviter le
  clobbering entre blocs successifs, cf. Déviations). +157 lignes net.

## Preuves de mutation (consignées littéralement, cf. `<output>` du plan)

Deux niveaux de preuve par tâche : (a) l'assertion discriminante **interne** au bloc de test
(rejouée à chaque run de la suite, sur une copie `mktemp -d` — jamais le fichier réel du dépôt) ;
(b) une injection/retrait **réel et éphémère** sur le fichier du dépôt, exécutée une fois pendant
ce plan et restaurée aussitôt après mesure. Les deux niveaux sont documentés ci-dessous avec
commande + compteur avant/après.

### Tâche 1 — T24 (mutation réelle sur `vf-dev-manager.md`)

```
AVANT (état conforme)  : 78 OK / 0 KO / 0 SKIP
Commande de mutation    : grep -v 'gate="blocking-human"' vf-dev-manager.md > copie ; copie → fichier réel
APRÈS MUTATION          : 77 OK / 2 KO / 0 SKIP   (T24 C, T24 D)
Commande de restauration: cp <sauvegarde pré-mutation> vf-dev-manager.md
APRÈS RESTAURATION      : 78 OK / 0 KO / 0 SKIP
```

### Tâche 2 — T25 (injection réelle dans `vf-dev-manager.md`)

```
AVANT (état conforme)  : 81 OK / 0 KO / 0 SKIP
Commande d'injection    : echo '2. **Plan** : invoque `gsd-plan-phase` en mode **non-interactif**.' >> vf-dev-manager.md
APRÈS INJECTION          : 79 OK / 1 KO / 0 SKIP   (T25 fermeture)
Commande de restauration: cp <sauvegarde pré-injection> vf-dev-manager.md
APRÈS RESTAURATION      : 81 OK / 0 KO / 0 SKIP
```

### Tâche 3 — T26 (injection réelle dans `vf-coder.md`)

```
AVANT (état conforme)  : 84 OK / 0 KO / 0 SKIP
Commande d'injection    : printf '\n**Completed Tasks** table (hashes + files) — ...\n' >> vf-coder.md
APRÈS INJECTION          : 82 OK / 1 KO / 0 SKIP   (T26 D NÉGATIVE)
Commande de restauration: cp <sauvegarde pré-injection> vf-coder.md
APRÈS RESTAURATION      : 84 OK / 0 KO / 0 SKIP
```

Chaque cycle mutation → KO → restauration → 0 KO a été exécuté réellement pendant ce plan (pas
seulement décrit) ; les sauvegardes intermédiaires ont vécu dans le scratchpad de session, jamais
commitées.

## Décisions Made

Voir `key-decisions` en frontmatter (D-01, D-02, D-03 révisée, D-04bis) — toutes tranchées en
amont au cadrage de la Phase 23, appliquées ici sans réinterprétation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `check-agents.sh --agents-dir <path>` (forme espace) ne fonctionne pas —
syntaxe `--agents-dir=<path>` requise**
- **Found during:** Tâche 1 (vérification `<acceptance_criteria>`)
- **Issue:** le plan (et ce mandat) citent littéralement `check-agents.sh --agents-dir
  plugin/dev-orchestrator/agents --strict` (séparé par un espace). Le script n'accepte QUE la
  forme `--agents-dir=PATH` (`case "$arg" in --agents-dir=*)`) ; en forme espace, l'argument est
  ignoré et `AGENTS_DIR` retombe sur son défaut `.claude/agents` (absent en disposition dépôt
  source) → `exit 3 INDETERMINE`.
- **Fix:** exécution de la commande de vérification avec `--agents-dir=plugin/dev-orchestrator/agents`
  (forme `=`) aux trois tâches. Aucun fichier du périmètre ne référence cette invocation — pas de
  fichier à corriger, seulement l'invocation de vérification elle-même. `check-agents.sh` n'est
  PAS dans `files_modified` de ce plan : documentation, pas correction du script.
- **Verification:** `check-agents.sh --agents-dir=plugin/dev-orchestrator/agents --strict` → exit 0,
  7 warnings pré-existants (skills non câblés, 3 noms d'agents tiers non résolus — hors périmètre),
  aux trois tâches.
- **Committed in:** n/a (pas un changement de fichier, une correction de commande d'exécution)

**2. [Rule 1 - Bug] « Puis quatre gestes non négociables » devient faux après l'ajout du geste 5**
- **Found during:** Tâche 2 (juste après l'édition du geste 5)
- **Issue:** `vf-dev-manager.md` §Discipline de pilotage annonçait littéralement « Puis quatre
  gestes non négociables » avant le geste 1 ; l'ajout du geste 5 (reset du flag) rend ce compte
  faux sans qu'aucune assertion machine ne le capture.
- **Fix:** `quatre` → `cinq`, une seule occurrence, 0 ligne nette ajoutée.
- **Files modified:** `plugin/dev-orchestrator/agents/vf-dev-manager.md` (inclus dans le diff
  déjà compté pour la Tâche 2).
- **Verification:** relecture visuelle + `wc -l` inchangé par cette correction.
- **Committed in:** `f302419` (commit Tâche 2)

**3. [Rule 1 - Bug] `trap ... EXIT` non cumulatif entre blocs de test successifs**
- **Found during:** Tâche 2 (avant d'ajouter le second bloc `mktemp -d` du fichier de test)
- **Issue:** bash n'a qu'UN SEUL slot de trap `EXIT` par shell — un second `trap 'rm -rf
  "$T25_TMPDIR"' EXIT` écraserait silencieusement le nettoyage de `$T24_TMPDIR` posé en Tâche 1,
  laissant un répertoire temporaire orphelin en cas de run normal (le script ne plante jamais,
  mais le cleanup du bloc précédent serait perdu).
- **Fix:** la commande de trap dans T24 (puis reprise identique dans T25 et T26) nettoie les
  trois répertoires `${T24_TMPDIR:-}"` `${T25_TMPDIR:-}"` `${T26_TMPDIR:-}` en une seule
  expression `2>/dev/null` — le dernier trap posé (celui de T26) couvre les trois, chacune des
  variables étant bien peuplée à ce stade de l'exécution.
- **Files modified:** `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (la ligne
  de trap de T24 a été retouchée en Tâche 2, dans le même commit `f302419`, avant l'ajout de T25).
- **Verification:** suite complète exécutée après chaque ajout de bloc, `0 KO` maintenu ; les
  trois `mktemp -d` disparaissent bien à la fin du run (`ls /tmp` post-run ne montre aucun
  répertoire orphelin de la suite).
- **Committed in:** `f302419` (commit Tâche 2, la ligne de trap T24 fait partie du diff)

---

**Total deviations:** 3 auto-corrigées (2 bugs de cohérence doctrine/texte, 1 bug de robustesse
script de test), toutes Rule 1. Aucune n'a touché de fichier hors du périmètre STRICT déclaré.
**Impact on plan:** aucune — les trois corrections sont internes aux fichiers déjà dans le
périmètre et nécessaires à la cohérence (le compte de gestes) ou à la robustesse (le trap
cumulatif) de ce que le plan demandait. Pas de dérive de portée.

## Issues Encountered

Aucun blocage. Le seul point de friction — la syntaxe `--agents-dir=` vs `--agents-dir ` — est
documenté ci-dessus comme déviation Rule 1 (commande de vérification, pas un fichier du
périmètre).

## Dernier geste de 23-01 — dégazage de `T25b` (A-1ter geste 1, 2026-08-03)

**Ce que c'est.** 23-01 était clos sur toute sa part mécanique, sauf O-8. L'arbitrage humain
**A-1ter** (`23-ARBITRAGES.md`) l'a tranché et a commandé, **immédiatement dans 23-01**, de retirer
à `T25b` une promesse qu'il ne tient pas. C'est le dernier geste du plan.

**Le fait.** `--auto` sur le cadrage n'arme pas seulement le chain flag : il **enchaîne
discuss → plan → execute dans le même appel** (`gsd-core@1.9.0`,
`workflows/discuss-phase/modes/chain.md` étape 5, l. 45-61). Le désarmement « adjacent » exigé par
A-1bis s'exécute donc **après tout le pipeline**. `T25b` certifie une adjacence **TEXTUELLE** ; il
**ne borne aucune fenêtre runtime** — son libellé prétendait le contraire.

**Ce qui a changé — de la PROSE, exclusivement.**

- Libellé `ok` et message `ko` de `T25b` réécrits : ils disent maintenant *adjacence textuelle dans
  le bloc Cadrage aplati, à ≤ 150 caractères*, et énoncent explicitement qu'aucune fenêtre runtime
  n'est bornée.
- En-tête du bloc `T25b` : deux sections neuves — **« ce qui est mesuré, et rien de plus »** et
  **« ce que cette sonde ne garantit PAS »** — plus la portée réelle **bornée** (règle 6 de
  `checkpoints.md` protège les gates `blocking-human` : ce n'est **pas** une violation d'ADR-031 sur
  le gate que 23-01 construit ; c'est la **règle 5** qui joue — `human-verify` auto-approuve et
  `decision` auto-sélectionne la première option pendant plan et execute) et le renvoi au correctif
  structurel (A-1ter geste 2, voie 1, instruite en **23-05**).
- Les deux messages `T25B_WHY` de KO qui parlaient de « fenêtre ouverte pour toute la mission » et
  de fenêtre « refermée » : corrigés — un message de KO doit rester exact.
- Renvois à `T25b` ailleurs dans le fichier (périmètre de `T25`, commentaire de la fixture `d`,
  commentaire du libellé gelé de `T25 fermeture`, balayage) : requalifiés en *adjacence textuelle*.

**Ce qui n'a PAS changé — invariance prouvée, pas au compteur.** `T25B_DISARM_RE`, `T25B_WINDOW`
(150), l'`awk` d'appariement, les fixtures `g`..`k`, les mutants `M1`..`M4`, les codes de retour et
tous les autres blocs : intacts. Preuve : verdicts matérialisés par assertion **avant** et **après**
(102 OK / 0 KO / 0 SKIP dans les deux cas), comparés en `comm` sur listes triées — **103 libellés
sur 104 identiques mot pour mot**, l'unique écart étant le libellé de `T25b` volontairement
réécrit ; multiset (statut + identifiant de test) **identique** (`cmp -s`) ; et séquence des lignes
de **code** (commentaires exclus) **identique ligne à ligne** hors les 4 chaînes de message
réécrites — 2160 lignes de code de part et d'autre.

**Exception assumée au gel des libellés `ok`.** L'acquis « on ajoute, on ne réécrit jamais » (cf.
O-4) protège les libellés qui **sous-déclarent** : ils ne mentent pas. Celui de `T25b`
**sur-déclarait** — il annonçait une garantie que la sonde ne rend pas. Un libellé qui ment n'est
pas un invariant à préserver, et A-1ter commande explicitement sa réécriture. C'est le **seul**
libellé touché, et l'écart est matérialisé plutôt qu'assumé de mémoire.

**Statut de `T25b` pour la suite.** Le jour où 23-05 fait porter le cadrage au manager, `T25b`
devient **sans objet** : à retirer, ou à remplacer par une garantie **runtime** — jamais à conserver
vert. La contrainte est écrite dans `23-05-PLAN.md` §« Contrainte d'entrée (A-1ter geste 2) ».

**Débordement d'allocation d'identifiants de bloc — constaté après coup (2026-08-03).**
`23-01-PLAN.md:113-115` allouait `T24`, `T25`, `T26` à ce plan et `T27` au plan 23-03. L'exécution
a posé `T24, T25, T25b, T25c, T26, T27, T27b, T27c` : les satellites `T25b`/`T25c` et surtout
`T27`/`T27b`/`T27c` (A-4, B4-B5) sont sortis de l'allocation, et `T27` a été pris au plan 23-03.
Le plan 23-03 a été **réattribué à `T33`** le 2026-08-03 — `T28`→`T32` restant revendiqués par
23-04 à 23-07, et le décalage en cascade coûtant plus que la réattribution d'un seul plan. Aucun
geste n'est repris ici : `23-01-PLAN.md` n'est pas réécrit, son allocation d'origine reste
l'archive de ce qui était prévu. Motif complet dans `23-03-PLAN.md` §« Numérotation du bloc de
test ».

## Densité restante — budget pour les plans 23-06 et 23-07

- `vf-dev-manager.md` : **244 lignes** / plafond ADR-029 = 250 → **6 lignes de marge**. Le plan
  23-01 avait annoncé un budget cumulé de +9 lignes (+2 tâche 1, +4 tâche 2, +3 tâche 3) ;
  consommation réelle nette = **+8 lignes** (236 → 244), légèrement sous l'annonce. Les plans
  23-06 (verdicts) et 23-07 (décompte) devront tenir dans ces 6 lignes restantes — toute
  extension au-delà nécessite une compression d'une phrase existante en renvoi (jamais une
  suppression de décision), comme prévu par le plan.
- `vf-coder.md` : **86 lignes** / plafond 250 → 164 lignes de marge, aucune tension prévisible.
- `mission-contracts.md` : 274 lignes (fichier de référence, pas soumis au plafond ADR-029 des
  agents) — aucune contrainte de densité machine sur ce fichier.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Le contrat de checkpoint amont (`gate`, `reprise`) est posé et gaté machine (T24, T26) : les
  plans 23-02 à 23-08 peuvent s'appuyer dessus sans le redéfinir.
- Le flag `workflow._auto_chain_active` est désarmé au démarrage de mission et fermé (T25) : la
  doctrine de flags du plan 23-03 peut désormais graduer les autres flags en connaissant celui-ci
  comme acquis.
- **Marge de densité tendue sur `vf-dev-manager.md`** (6 lignes) : signalé explicitement pour les
  auteurs des plans 23-06/23-07 (§Densité restante ci-dessus).
- Aucun blocage pour la suite de la Phase 23.

---
*Phase: VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-*
*Plan: 01*
*Completed: 2026-08-01*
