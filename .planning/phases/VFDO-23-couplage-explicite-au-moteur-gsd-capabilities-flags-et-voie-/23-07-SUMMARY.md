---
phase: VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-
plan: 07
subsystem: dev-orchestrator
tags: [mission-flow, mission-contracts, vf-dev-manager, GSD-PIPELINE, budget-partage, briques-dormantes, D-22, test-discriminance]

# Dependency graph
requires:
  - phase: 23-03
    provides: GSD-PIPELINE.md §9 (voie unique d'invocation par skill), réservation des numéros de
      bloc de test T31/T32 à l'intention de ce plan
  - phase: 23-06
    provides: état stabilisé de mission-contracts.md / vf-dev-manager.md (champ verdicts), budget
      de densité restant pour vf-dev-manager.md (241/250)
provides:
  - Budget de tours UNIQUE, au grain ÉTAPE, partagé entre les boucles de correction qui reprennent
    le même problème — remplace (jamais ne double) la mention de deux budgets séparés
  - Sous-section « Épuisement du budget » (mission-flow.md §Pattern E §6) : statut `blocked` +
    décompte complet (tours consommés par boucle, findings non résolus), invisibilité amont du
    coût interne du moteur (node_repair) nommée comme un fait sourcé, jamais un total inventé
  - Champ optionnel `decompte` (mission-contracts.md), quatrième frère de gate/reprise/verdicts,
    présent uniquement au statut `blocked`
  - Table « Briques dormantes — moments déclencheurs » (mission-flow.md), gabarit
    Déclencheur|Constat repris de docs-flow.md, quatre briques nommées (gsd-extract-learnings,
    gsd-add-tests, gsd-spec-phase, gsd-undo/gsd-forensics)
  - Mandat de debug qui passe par le skill `gsd-debug` (jamais un agent nu), câblé dans
    vf-dev-manager.md et GSD-PIPELINE.md §7
  - Constante dérivée `BRIQUES_NUES_DISPATCH_RE` (test-dev-orchestrator.sh), consommée par la
    seule `brique_nue_dispatch_hits()` — `BRIQUES_NUES_RE` elle-même reste inchangée
  - T31 (7 assertions) et T32 (7 assertions + garde de fonction unique) dans
    test-dev-orchestrator.sh, discriminance prouvée par mutation (T31-E, T32-D-bis, T32-F)
affects: [23-08]

# Actuals (#2632) — pairs with the plan's estimate to calibrate future estimates.
# Same estimateTokens scale (chars/4 over the realized diff), never a harness token count.
# Mesuré sur `rtk proxy git diff f3fcfc0 HEAD -- <5 fichiers du périmètre>` (méthode reprise de
# 23-06) : numstat = mission-flow.md +43/-4, mission-contracts.md +11/-0, vf-dev-manager.md
# +6/-2, GSD-PIPELINE.md +2/-0, test-dev-orchestrator.sh +228/-1. chars/4 sur les lignes +/- du
# patch (hors en-têtes diff/index, `grep -E '^\+[^+]|^-[^-]'`) = 20246 / 4 = 5061.5, arrondi 5062.
actuals:
  tokens: 5062
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Budget d'étape écrit au GRAIN (« partagé par étape »), jamais comme une liste fermée de
      boucles nommées — un grain couvre toute boucle qui reprend le même problème sous un autre
      nom, une liste énumérée se contourne par renommage (D-27)"
    - "Constante dérivée de portée LIMITÉE (BRIQUES_NUES_DISPATCH_RE référence BRIQUES_NUES_RE
      sans la recopier, et n'est consommée que par la fonction de détection de dispatch) — étendre
      directement la constante balayée fichier entier aurait couplé le gate à un écart connu et
      non tranché (D-22/vf-coder.md tools:), mesuré ROUGE et donc écarté"
    - "Co-présence bornée AU BLOC (md_blocks_matching, patron t23_triggers_colocated), jamais un
      grep global sur des mots isolés — trois mots séparément vrais partout dans un fichier de
      cette taille ne prouvent aucune relation entre eux (famille de bug déjà nommée en 2026-08-01)"

key-files:
  created: []
  modified:
    - plugin/dev-orchestrator/references/mission-flow.md
    - plugin/dev-orchestrator/references/mission-contracts.md
    - plugin/dev-orchestrator/agents/vf-dev-manager.md
    - plugin/dev-orchestrator/references/GSD-PIPELINE.md
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh

key-decisions:
  - "D-27 (tâche 1) : le grain du budget partagé est l'ÉTAPE, pas la mission (pénaliserait les
    étapes tardives) et pas une liste fermée de boucles (D-27 nomme revue+comblement, le manager
    nommait vérification+revue — ce sont TROIS boucles dans la même étape, couvertes par le grain,
    pas par leur énumération)."
  - "D-25 : la VALEUR du budget (3 tours) est inchangée — un critère machine (T31-F) le garde
    explicitement vert d'avance, en garde de NON-régression contre un plafonnement opportuniste."
  - "D-26 : l'invisibilité amont du coût interne du moteur (node_repair) est écrite comme un fait
    daté et sourcé (journal amont = prose libre, aucun champ de comptage), jamais compensée par un
    total agrégé inventé."
  - "Tâche 3, forme imposée par mesure préalable : étendre DIRECTEMENT BRIQUES_NUES_RE pour y
    ajouter l'agent nu de debug rend la suite ROUGE (T29-A grepe vf-coder.md fichier ENTIER, ligne
    tools: comprise) — donc INTERDIT. La constante dérivée BRIQUES_NUES_DISPATCH_RE, consommée par
    la seule fonction de détection de dispatch en corps de prompt, rend la suite VERTE et laisse
    l'écart D-22 (ligne tools:) intact et non tranché par ce plan."
  - "Piège de littéral (mesuré) : le corps de vf-dev-manager.md nomme le skill `gsd-debug`, jamais
    l'identifiant complet de l'agent nu de debug — même pour l'interdire, l'écrire en toutes
    lettres ferait rougir T29-B (détection sur le corps de prompt, pas sur l'intention)."

patterns-established:
  - "Champ optionnel `decompte`, quatrième frère de gate/reprise/verdicts dans le bloc typé,
    présent uniquement au statut `blocked` — même contrat que ses frères (recopié, jamais estimé)"
  - "Table de moments déclencheurs, gabarit Déclencheur|Constat, réutilisable pour toute famille
    de briques dormantes future — la forme est déjà lue par le manager (docs-flow.md), aucun
    format nouveau à apprendre"

requirements-completed: [GSDC-08, GSDC-09]

coverage:
  - id: D1
    description: "Budget de tours partagé PAR ÉTAPE (grain, pas liste de boucles), remplaçant la
      formulation de deux budgets séparés dans vf-dev-manager.md"
    requirement: GSDC-08
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T31-A/T31-D/T31-E"
        status: pass
    human_judgment: false
  - id: D2
    description: "Sous-section « Épuisement du budget » : statut blocked + décompte complet +
      invisibilité amont nommée (node_repair) + interdiction de la proposition de next step"
    requirement: GSDC-08
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T31-B/T31-C"
        status: pass
    human_judgment: false
  - id: D3
    description: "Champ decompte dans mission-contracts.md (bloc typé + gabarit §Rapport de
      mission)"
    requirement: GSDC-08
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T31-D"
        status: pass
    human_judgment: false
  - id: D4
    description: "Table « Briques dormantes — moments déclencheurs » (4 briques, gabarit
      Déclencheur|Constat, clôture état normal) dans mission-flow.md"
    requirement: GSDC-09
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T32-A/T32-B/T32-F"
        status: pass
    human_judgment: false
  - id: D5
    description: "Mandat de debug via le skill gsd-debug (jamais un agent nu) câblé dans
      vf-dev-manager.md (2 touches) et GSD-PIPELINE.md §7, aucun dispatch d'agent nu de debug en
      corps de prompt nulle part dans le module"
    requirement: GSDC-09
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T32-C/T32-D/T32-Dbis"
        status: pass
    human_judgment: false
  - id: D6
    description: "Écart D-22 (ligne tools: de vf-coder.md porte gsd-debugger) remonté à
      l'arbitrage humain — ni retiré ni entériné par ce plan"
    verification: []
    human_judgment: true
    rationale: "Retirer ou légitimer une entrée d'allowlist d'un worker est un geste de périmètre
      sous ADR-031, hors mandat de l'exécutant de ce plan. Samuel doit trancher : soit retirer
      gsd-debugger de vf-coder.md, soit amender D-22 pour y inscrire l'exception et son motif."

duration: ~30min
completed: 2026-08-04
status: complete
---

# Phase 23 Plan 07: Budget de tours partagé par étape + briques dormantes + mandat de debug via skill Summary

**Budget de tours UNIQUE partagé par étape (fin du contournement par renommage), décompte complet
à l'épuisement avec l'invisibilité amont du moteur nommée, table de moments déclencheurs pour
quatre briques dormantes, et mandat de debug qui passe par le skill `gsd-debug` — écart D-22 sur
la ligne `tools:` de `vf-coder.md` consigné comme ouvert, non tranché.**

## Performance

- **Duration:** ~30 min (session de lecture + édition + tests, pas de checkpoint)
- **Started:** 2026-08-04 (lecture intégrale du plan, worktree `vibeflow-os-p23`)
- **Completed:** 2026-08-04T04:33Z
- **Tasks:** 3/3
- **Files modified:** 5

## Accomplissements

- **Tâche 1** — le budget de la boucle de correction de revue (Pattern E §2 de `mission-flow.md`)
  est devenu un budget **UNIQUE**, au grain **ÉTAPE**, écrit comme un grain plutôt que comme une
  liste fermée de boucles (D-27 nomme revue+comblement, le manager nommait
  vérification+revue — ce sont trois boucles dans la même étape, toutes couvertes par le grain).
  Nouvelle sous-section **§6 Épuisement du budget** : statut `blocked` + décompte complet (tours
  de revue/comblement consommés, findings non résolus — « le décompte EST la livraison ») +
  invisibilité amont du coût interne du moteur (`node_repair`) nommée comme un fait daté et
  sourcé + interdiction explicite de joindre une proposition de next step. `mission-contracts.md`
  gagne le champ optionnel `decompte`, quatrième frère de `gate`/`reprise`/`verdicts`. La
  formulation « deux budgets séparés » de `vf-dev-manager.md` (point 3) est **remplacée**, pas
  doublée.
- **Tâche 2** — nouvelle table « Briques dormantes — moments déclencheurs » dans
  `mission-flow.md`, gabarit `Déclencheur | Constat` repris à l'identique de `docs-flow.md`,
  quatre lignes (extraction de savoir → `gsd-extract-learnings`, ajout de tests →
  `gsd-add-tests`, spécification d'étape → `gsd-spec-phase`, récupération → `gsd-undo` /
  `gsd-forensics`). `vf-dev-manager.md` gagne deux touches d'une ligne : le manager ne debug pas,
  il redispatche le worker en mandat de debug qui invoque le skill `gsd-debug` ; et un renvoi vers
  la nouvelle table. `GSD-PIPELINE.md` §7 gagne une ligne rappelant que la brique de debug
  s'invoque par son skill, cohérent avec §9.
- **Tâche 3** — bloc `T32` (test-dev-orchestrator.sh) qui gate la table et le mandat de debug.
  Constante dérivée `BRIQUES_NUES_DISPATCH_RE` posée au-dessus de `brique_nue_dispatch_hits()`,
  consommée UNIQUEMENT par cette fonction — `BRIQUES_NUES_RE` elle-même reste inchangée et continue
  d'alimenter `T29-A/E/G` en balayage fichier entier.

## Task Commits

Chaque tâche a été committée atomiquement, avec pathspec explicite (jamais `git add -A`) :

1. **Tâche 1 : budget de tours partagé par étape, décompte à l'épuisement** — `a3bf5d3` (feat)
   — `mission-flow.md`, `mission-contracts.md`, `vf-dev-manager.md`,
   `test-dev-orchestrator.sh` (bloc `T31`)
2. **Tâche 2 : moment déclencheur pour quatre briques dormantes, mandat de debug via skill** —
   `ed54bef` (feat) — `mission-flow.md`, `vf-dev-manager.md`, `GSD-PIPELINE.md`
3. **Tâche 3 : gate T32 sur la table des briques dormantes et le mandat de debug** — `90c659c`
   (test) — `test-dev-orchestrator.sh` (constante dérivée + bloc `T32`)

`mission-flow.md` et `vf-dev-manager.md` sont modifiés par les tâches 1 ET 2 : pour garder un
commit strictement scopé à chaque tâche, le contenu de la tâche 2 a été temporairement retiré
(Edit), la tâche 1 committée seule, puis le contenu de la tâche 2 réintroduit et committé
séparément — aucun contenu perdu, chaque commit ne porte que le diff de sa propre tâche (vérifié
`git diff` entre commits).

**Pas de commit de métadonnées séparé** : la mission qui a dispatché cet exécuteur porte son
propre cycle de bookkeeping (`.planning/HANDOFF.json`, `.planning/MISSION-23.dag.json`) — ces
fichiers sont gelés pour ce mandat et ne sont touchés par aucun des 3 commits ci-dessus (vérifié :
`rtk proxy git diff f3fcfc0 HEAD --stat` ne les liste pas).

## Files Created/Modified

- `plugin/dev-orchestrator/references/mission-flow.md` (+43/-4 lignes) — Pattern E §2 remplacé,
  nouvelle §6 Épuisement du budget, nouvelle section Briques dormantes
- `plugin/dev-orchestrator/references/mission-contracts.md` (+11/-0 lignes) — champ `decompte`,
  ligne symétrique au gabarit Rapport de mission
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` (+6/-2 lignes nettes, 241 → 245/250) — point 3
  remplacé (tâche 1), mandat de debug + renvoi briques dormantes (tâche 2)
- `plugin/dev-orchestrator/references/GSD-PIPELINE.md` (+2/-0 lignes) — §7, voie du debug
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (+228/-1 lignes) — constante
  dérivée `BRIQUES_NUES_DISPATCH_RE`, blocs `T31` et `T32`

## Nombre de lignes final de vf-dev-manager.md et reliquat pour 23-08

**Mesure fiable** : `awk 'END{print NR}' plugin/dev-orchestrator/agents/vf-dev-manager.md` →
**245**. `wc -l < plugin/dev-orchestrator/agents/vf-dev-manager.md` (redirection stdin) a été
**mesuré cassé sur ce poste de dev** pendant l'exécution — il rend faussement `0` alors que
`wc -l plugin/dev-orchestrator/agents/vf-dev-manager.md` (sans redirection) et
`awk 'END{print NR}' …` rendent tous deux `245` de façon cohérente. Le critère d'acceptation du
plan portait littéralement la forme `wc -l < fichier` : elle n'a **pas** été utilisée pour la
mesure retenue ci-dessus, remplacée par `awk 'END{print NR}'` (contournement documenté aussi dans
le prompt de dispatch de cette mission).

- Base mesurée avant ce plan : **241/250**
- +1 lignes nettes tâche 1 (remplacement, pas d'ajout net — la phrase de remplacement tient dans le
  même nombre de lignes que l'originale)
- +4 lignes nettes tâche 2 (mandat de debug : 3 lignes ; renvoi briques dormantes : 1 ligne)
- **Total : 245/250**
- **Reliquat en clair pour le plan 23-08 : 5 lignes.** Ce chiffre est mesuré, pas estimé — 23-08
  hérite d'une marge réelle de 5 lignes sur `vf-dev-manager.md`, pas d'une hypothèse.

## Preuves de mutation (avant/après)

### Assertion E (tâche 1) — formulation de budget séparé, discriminance de T31-D

```
$ grep -c 'son propre budget' plugin/dev-orchestrator/agents/vf-dev-manager.md
0                                                              # fichier RÉEL, après édition

$ sed "s/pas doublé/pas doublé (chacune garde son propre budget et son propre \`reopen\`)/" \
    plugin/dev-orchestrator/agents/vf-dev-manager.md | grep -c 'son propre budget'
1                                                              # MUTANT (réinjection), détecté
```
Le mutant n'est pas identique au fichier réel (`cmp -s` le confirme dans T31-E), et la réinjection
de la formulation interdite fait passer le compteur de `0` à `1` — la garde négative discrimine
réellement.

### Assertion F (tâche 3) — retrait d'une brique, discriminance de T32-B/F

```
# AVANT (fichier réel, les 3 briques ciblées par la boucle sont présentes) :
présent: gsd-extract-learnings
présent: gsd-add-tests
présent: gsd-spec-phase

# APRÈS (mutant : `grep -v 'gsd-add-tests' mission-flow.md`) :
présent: gsd-extract-learnings
MANQUANT: gsd-add-tests
présent: gsd-spec-phase
```
Le retrait d'UNE seule ligne fait échouer la boucle en nommant précisément `gsd-add-tests` comme
manquant — preuve que la boucle vérifie bien les quatre entrées une par une, pas « au moins une ».

### Assertion D-bis (tâche 3) — dispatch d'agent nu de debug, discriminance DANS LES DEUX SENS

```
# sens ROUGE : dispatch direct de l'agent nu de debug injecté en corps de prompt d'une copie
$ awk '!/^tools:/' <copie-avec-injection>.md | grep -oE 'gsd-planner|gsd-executor|gsd-debugger'
gsd-debugger                                                   # détecté

# sens VERT : fichier réel
$ awk '!/^tools:/' plugin/dev-orchestrator/agents/vf-dev-manager.md \
    | grep -oE 'gsd-planner|gsd-executor|gsd-debugger'
(vide — 0 hit)

# sens VERT : contre-épreuve, copie ne nommant QUE le skill (préfixe strict du nom d'agent)
$ awk '!/^tools:/' <copie-skill-seul>.md | grep -oE 'gsd-planner|gsd-executor|gsd-debugger'
(vide — 0 hit)
```
L'extension du motif de détection (`BRIQUES_NUES_DISPATCH_RE`) rougit sur l'injection réelle,
tout en laissant vert et le fichier réel et une reformulation licite (skill nommé, pas l'agent) —
elle ne condamne donc pas à tort le livrable de la tâche 2.

## Decisions Made

Voir `key-decisions` en frontmatter — résumé :

- Le grain du budget partagé est l'**étape** (D-27), écrit comme grain et non comme énumération
  fermée de boucles (trois boucles réelles couvertes : revue, vérification, comblement).
- La **valeur** du budget (3 tours) reste inchangée (D-25) — gardée par un critère machine
  explicitement vert d'avance (T31-F), en garde de non-régression contre un plafonnement
  opportuniste, pas comme preuve de livraison.
- L'invisibilité amont du coût interne du moteur (`node_repair`) est **nommée** plutôt que
  compensée par un chiffre inventé (D-26).
- Tâche 3 : `BRIQUES_NUES_DISPATCH_RE` est une constante **dérivée** de `BRIQUES_NUES_RE`,
  consommée UNIQUEMENT par `brique_nue_dispatch_hits()`. Étendre directement `BRIQUES_NUES_RE`
  a été **mesuré et écarté** : cela rend la suite ROUGE (`T29-A : vf-coder.md contient encore
  [ gsd-debugger ]`), parce que `T29-A` balaie le fichier ENTIER de `vf-coder.md`, ligne `tools:`
  comprise — cela aurait couplé le gate de dispatch à l'écart D-22 encore ouvert.

## 🛑 Écart D-22 — ÉCART OUVERT, remonté à l'arbitrage humain (jamais un constat clos)

**Fait mesuré, non interprété** : `plugin/dev-orchestrator/agents/vf-coder.md`, ligne `tools:`,
porte l'entrée d'allowlist `gsd-debugger` — **1 occurrence, seule occurrence de ce nom dans tout
`plugin/dev-orchestrator/agents/`** (mesure inchangée depuis le début de ce plan, ce plan n'y a
touché en aucune façon). Or **D-22 est tranché par Samuel** : « aucun `gsd-debugger` en allowlist,
aucune exception ». L'existant **contredit donc frontalement** cette décision verrouillée.

**Ce que ce plan a fait** : traité le **volet dispatch** (aucun agent nu de debug offert en
dispatch direct dans le corps de prompt d'aucun agent du module — T32-D, gaté, discriminance
prouvée dans les deux sens). **Ce que ce plan n'a PAS fait, et n'avait pas mandat de faire** :
retirer l'entrée `gsd-debugger` de la ligne `tools:` de `vf-coder.md`, ou légitimer son maintien.
Retirer une entrée d'allowlist d'un worker est un geste de périmètre sous ADR-031 — hors mandat de
cet exécuteur.

**Arbitrage attendu de Samuel** : soit retirer `gsd-debugger` de l'allowlist de `vf-coder.md` et
rendre D-22 vrai en machine, soit amender D-22 pour y inscrire l'exception et son motif. **Tant que
cet arbitrage n'est pas rendu, aucune affirmation de ce SUMMARY ne doit se lire comme une
conformité totale à D-22** — ce plan est conforme au **volet dispatch**, et à lui seul. La
constante dérivée `BRIQUES_NUES_DISPATCH_RE` a d'ailleurs été conçue **précisément** pour ne pas
toucher, ni faire dépendre son verdict de, cette ligne `tools:`.

## [W5] Numérotation non monotone des blocs de test — volontaire, pas un désordre

Ce plan pose `T31` et `T32` dans `test-dev-orchestrator.sh`, alors que `T33` existe **déjà** dans
le fichier (posé par le plan 23-03, après une collision sur `T27` tranchée le 2026-08-03, avec la
consigne explicite « aucun autre plan ne bouge »). `T31` et `T32` étaient **explicitement
réservés** à ce plan par des commentaires posés en 23-05 et 23-06 — vérifié dans les commentaires
de tête des blocs `T29` (« PARTAGÉE avec le bloc `T32` de 23-07-PLAN.md ») et sur la constante
`BRIQUES_NUES_RE` elle-même. La numérotation `T29 → T30 → T33 → T31 → T32` (ordre physique dans le
fichier) est donc **traçable et volontaire**, reflet de l'ordre de dispatch des plans plutôt que
de l'ordre séquentiel des numéros. **Aucun renumérotage n'a été fait**, conformément à la consigne
héritée de 23-03.

## Deviations from Plan

**Aucune déviation au sens des règles 1-4** — le plan a été exécuté tel qu'écrit, y compris ses
clauses de garde-fou (grain plutôt que liste de boucles, forme dérivée plutôt que directe pour
`BRIQUES_NUES_DISPATCH_RE`, budget de densité tenu à 245/250 pile).

Deux ajustements de formulation, **prévus par le plan lui-même** (pas des découvertes en cours de
route) :
- Le texte du mandat de debug dans `vf-dev-manager.md` a été raccourci une fois (de 4 à 3 lignes
  physiques) pour rester dans le budget de densité de la tâche 2 (+3 lignes annoncées) — aucune
  garantie perdue, seulement une reformulation plus dense du même contenu (skill nommé, motif du
  moment persistant, interdiction de l'agent nu).
- La fonction de garde « brique_nue_dispatch_hits() n'est définie qu'une fois » (ajoutée de mon
  initiative pour renforcer la non-régression de l'assertion D de T32) grepait initialement TOUTES
  les occurrences de la chaîne `brique_nue_dispatch_hits()`, y compris dans mes propres
  commentaires de prose — ancrée sur `^brique_nue_dispatch_hits\(\)[[:space:]]*\{` pour ne matcher
  que la définition de fonction réelle. Corrigé avant tout commit (visible uniquement dans
  l'historique d'édition de cette session, pas dans le diff final).

## Issues Encountered

- `wc -l < fichier` (redirection stdin) a été confirmé cassé sur ce poste pendant l'exécution —
  rend `0` au lieu de `245` sur `vf-dev-manager.md`. Contournement : `awk 'END{print NR}' fichier`
  ou `wc -l fichier` (sans `<`), cohérents entre eux. Documenté ici pour que 23-08 ne retombe pas
  dans le même piège en reprenant le critère d'acceptation littéral du plan.

## User Setup Required

None - aucune configuration de service externe requise.

## Résultat final de la suite

```
$ bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh > /tmp/x.log 2>&1; rc=$?; tail -5 /tmp/x.log; exit $rc
== résultat : 161 OK / 0 KO / 0 SKIP ==
RC=0
```

`check-agents.sh` (forme collée, sans espace avant le chemin) :
```
$ bash plugin/conductor/scripts/check-agents.sh --agents-dir=plugin/dev-orchestrator/agents --strict
[check-agents] ✓ agents conformes (natif + charte VibeFlow) · 7 warning(s)
RC=0
```
7 warnings = baseline attendue (mesurée identique avant ce plan), `--strict` ne fait pas échouer
sur des warnings.

## Next Phase Readiness

- Le plan 23-08 hérite d'un reliquat mesuré de **5 lignes** sur `vf-dev-manager.md` (245/250) et
  doit composer avec ce plafond quasi épuisé — la clause de déport ex ante (destination
  `mission-contracts.md` §Rapport de mission) reste disponible s'il le crève.
- L'écart D-22 (ligne `tools:` de `vf-coder.md`) reste **ouvert et non tranché** — un blocage pour
  toute future assertion qui voudrait certifier la conformité TOTALE à D-22 (au-delà du seul
  volet dispatch que ce plan couvre). Nécessite un arbitrage humain de Samuel avant d'être fermé.
- La numérotation des blocs de test (`T29 → T30 → T33 → T31 → T32`) est stable et documentée
  (W5) — aucune action requise, ne pas la « corriger » en renumérotant.

---
*Phase: VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-*
*Completed: 2026-08-04*
