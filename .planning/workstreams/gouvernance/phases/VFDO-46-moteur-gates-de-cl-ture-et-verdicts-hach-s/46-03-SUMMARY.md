---
phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s
plan: 03
subsystem: planning-core (recalcul d'état dérivé du disque)
tags: [recalcul, empreintes, a-clore, cache-v2, r4, predicat-partage, jetons-de-banc, mutants]

requires:
  - phase: 46-moteur-gates-de-cloture-et-verdicts-haches
    provides: bloc partagé livrable_present / empreinte_livrables (copie ast-identique dormante dans recalc-planning.sh), champ hash_livrables, bornes 2000 / 134217728, exclusions .DS_Store / Thumbs.db / desktop.ini, poser-verdict.sh
provides:
  - R4 par le prédicat partagé « livrable présent » : absent, lien, vide, hors borne (livrable-absent, livrable-vide, livrable-hors-borne)
  - règle E après R6 : vérification des deux empreintes du verdict (verdict-perime sans SUMMARY.md, livrable-modifie-apres-cloture avec, empreinte-hors-borne)
  - neuvième état dérivé à clore, non terminal, à la place d'indéterminé (verdict-passe-sans-SUMMARY.md, code disparu)
  - cache du recalcul de schéma 2, lié à l'état des livrables, recalculé à chaque passage
  - rendu de la raison d'un à juger périmé dans INDEX.md et STATE.md, remontée de la raison du plan à la phase et au cycle
  - jetons de banc {{sha256-plan}} et {{empreinte-livrables}} résolus par la copie du bloc lue dans poser-verdict.sh (matérialiseurs du recalcul et des gates)
  - référence modele-cycles.md et gabarit VERDICT.template.md à neuf états
affects: [46-05, 46-06, 46-07, 46-09, 46-10, 46-12]

plan_head_before: c60d56f13a2eb2b22fed3a9b5f9ee95ab2e5ceb2
estimate:
  tokens: 170000
  raw_tokens: 170000
  tasks: 3
  confidence: low
actuals:
  tokens: 18673    # chars/4 sur les lignes ajoutées et retirées sous plugin/ des trois commits de code (diff de la base au HEAD), pas un compte du harnais
  tasks: 3
  commits: 3       # MESURE : git rev-list --count c60d56f1..HEAD au moment de l'écriture du SUMMARY (commits de code, hors commit du SUMMARY)

tech-stack:
  added: []
  patterns:
    - "jeton de banc résolu après l'écriture de tous les fichiers du lab, par la copie du bloc partagé lue dans la commande de pose (preuve croisée, jamais par la copie du recalcul)"
    - "valeur de cache comparable d'un passage à l'autre (empreinte ou statuts des livrables) plutôt qu'un booléen d'existence"
    - "balises de fin de ligne uniques ciblées par un mutant : # r4-predicat, # r-empreintes, # r-empreintes-livrables, # r8-a-clore, # cache-empreinte"

key-files:
  created: []
  modified:
    - plugin/planning-core/scripts/recalc-planning.sh
    - plugin/planning-core/scripts/tests/test-recalc-planning.sh
    - plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt
    - plugin/planning-core/scripts/tests/test-planning-gates.sh
    - plugin/planning-core/references/modele-cycles.md
    - plugin/planning-core/references/templates/cycles/VERDICT.template.md

key-decisions:
  - "R4 : un livrable illisible rend livrable-absent:<entrée> (non établi présent), sans code nouveau ; l'entrée citée est celle déclarée dans ecrit:, la première fautive dans l'ordre déclaré"
  - "libellé de verdict-perime : « verdict périmé : re-juger (tentative n+1) » littéral, n+1 étant la formule de G4 et du plan, pas un nombre calculé (la tentative d'une phase à plans n'existe pas au niveau de la phase)"
  - "cache : la valeur stockée est comparable (état des livrables), pas une empreinte seule : une entrée dont des livrables sont absents, vides ou liens reste reprise tant que leurs statuts sont inchangés (voir écart 1)"
  - "le jumeau « -dev » du plan est, dans le banc de recalcul, un jumeau de dérivation (jumeau-de=, même unité, autre état), conformément à R20 : le recalcul ne se tait pas hors adhésion en lecture seule"

requirements-completed: [CLOT-01, CLOT-03, CLOT-04]

coverage:
  - id: D1
    description: "R4 par le prédicat partagé : un livrable vide, lien, dossier vide ou ne portant qu'un .DS_Store rend indéterminé (livrable-vide ou livrable-absent), chacun avec son jumeau"
    requirement: "CLOT-01"
    verification:
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh#R-R4VIDE-01, MUT-R4-VIDE, MUT-LIVRABLES"
        status: pass
    human_judgment: false
  - id: D2
    description: "Règle E : les deux empreintes du verdict vérifiées, verdict périmé rend à juger (verdict-perime) sans SUMMARY.md et indéterminé (livrable-modifie-apres-cloture) avec ; un verdict sans hash_livrables est périmé ; un PLAN.md modifié le périme"
    requirement: "CLOT-03"
    verification:
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh#R-PERIME-01, R-PERIME-02, MUT-EMPREINTES-RECALC"
        status: pass
    human_judgment: false
  - id: D3
    description: "Neuvième état à clore, non terminal, rendu tel quel par l'agrégat du cycle, par INDEX.md et STATE.md ; ancien code verdict-passe-sans-SUMMARY.md disparu"
    requirement: "CLOT-04"
    verification:
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh#R-CLORE-01, R27, R20, MUT-A-CLORE"
        status: pass
    human_judgment: false
  - id: D4
    description: "Cache de schéma 2 : un close en cache ne survit plus à la réécriture d'un livrable (même taille), un cache de schéma 1 est relu comme autre-format"
    requirement: "CLOT-03"
    verification:
      - kind: unit
        ref: "plugin/planning-core/scripts/tests/test-recalc-planning.sh#R-CACHE2-01, R-CACHE2-02, R58, MUT-LIVRABLES-CACHE"
        status: pass
    human_judgment: false
  - id: D5
    description: "Jetons de banc résolus par la copie du bloc lue dans poser-verdict.sh, dans les deux matérialiseurs (recalcul et gates) ; un jeton non résolu fait échouer le lab avec un message nommé"
    verification:
      - kind: integration
        ref: "test-recalc-planning.sh#R01, R-JETON-01 ; VF_GATES_SECTIONS=g1,banc test-planning-gates.sh (CROISE-G1)"
        status: pass
    human_judgment: false
  - id: D6
    description: "modele-cycles.md (neuf états, R4 absent ou vide, règle E, état à clore, codes, libellés, cache v2, conséquence voulue) et VERDICT.template.md"
    verification: []
    human_judgment: true
    rationale: "Prose de référence : seule la structure (titre, tables, présence des motifs) est contrôlée par R-REFERENCE et par l'awk du plan ; la justesse du texte est relue par le vérificateur de phase."

duration: 53min
completed: 2026-10-03
status: complete
---

# Phase 46 Plan 03: Recalcul, empreintes vérifiées et état à clore Summary

**Le recalcul lit le modèle posé par 46-01 : R4 « absent ou vide » par le prédicat partagé, règle E des deux empreintes (à juger verdict-perime avant SUMMARY.md, indéterminé livrable-modifie-apres-cloture après), neuvième état non terminal à clore, et un cache de schéma 2 qui ne garde plus jamais un close sur un livrable réécrit**

## Performance

- **Duration:** 53 min (début 15:22:53Z, fin 16:16Z)
- **Started:** 2026-10-03T15:22:53Z
- **Completed:** 2026-10-03T16:16:00Z
- **Tasks:** 3 (1 traceur, 2 auto, TDD sur les deux premières)
- **Files modified:** 6 (aucun créé)

## Accomplishments

- **R4 par le prédicat partagé** : `livrable_present` (copie ast-identique de 46-01, lue par `recalc-planning.sh`) rend `livrable-absent:<entrée>` (absent, lien, illisible), `livrable-vide:<entrée>` ou `livrable-hors-borne:<entrée>`. Le jumeau de chaque cas (livrable non vide, fichier réel à la place du lien, fichier ordinaire à côté d'un `.DS_Store`) rend `à juger`.
- **Règle E entre R6 et R7** : `hash` comparé au sha256 des octets du `PLAN.md`, `hash_livrables` à `empreinte_livrables` ; écart ou clé absente rend `à juger` (`verdict-perime`) sans `SUMMARY.md`, `indéterminé` (`livrable-modifie-apres-cloture`) avec ; borne dépassée pendant le calcul rend `empreinte-hors-borne`. R7 et R8 ne s'appliquent qu'à un verdict conforme. La conséquence voulue est prouvée : un verdict en échec suivi d'une correction du livrable repasse de `à corriger` à `à juger`.
- **Neuvième état `à clore`** (non terminal, aucune ligne de `cloture.log`) : l'agrégat du cycle, `INDEX.md`, `STATE.md` et `compte_par_etat` le rendent tel quel ; `verdict-passe-sans-SUMMARY.md` n'est plus produit ni attendu nulle part (`awk` du critère d'acceptation : 0 ligne).
- **Rendu de la péremption** : la raison `verdict-perime` d'un `à juger` remonte du plan à la phase et au cycle et se lit « à juger — verdict périmé : re-juger (tentative n+1) » dans `INDEX.md` et `STATE.md` ; un `à juger` ordinaire reste `à juger`.
- **Cache de schéma 2** : l'entrée porte l'état des livrables recalculé à chaque passage ; un octet d'un livrable réécrit à taille égale fait recalculer l'unité (R-CACHE2-01), un cache de schéma 1 est relu `autre-format` avec un résultat identique au recalcul sans cache (R-CACHE2-02) ; aucune signature par date.
- **Jetons de banc** `{{sha256-plan}}` et `{{empreinte-livrables}}` : treize verdicts valides du banc de recalcul, quatre verdicts écrits en ligne dans la suite ; résolution par la copie du bloc lue dans `poser-verdict.sh` (preuve croisée), dans les deux matérialiseurs ; un jeton non résolu fait échouer le lab avec un message nommé (R-JETON-01).
- **Référence** : `modele-cycles.md` à neuf états, R4, règle E, section « L'état à clore » (P44-D-08 levée sur ce point), codes, libellés, cache v2 et son coût déclaré ; `VERDICT.template.md` dit « vérifiés par le recalcul (règle E) et par G4 ».
- **Cinq mutants tués avec trace** (voir ci-dessous) ; la suite passe de 358 à 398 OK.

## Task Commits

1. **Task 1 (traceur) : état « à clore » et empreintes vérifiées au recalcul** - `dc579231` (feat)
2. **Task 2 : cache du recalcul sourd à aucune réécriture de livrable** - `b196b62d` (feat)
3. **Task 3 : neuf états, R4 absent ou vide et empreintes vérifiées dans la référence** - `dad32f8e` (docs, aucun fichier sous `scripts/` : pas de trailer)

**Plan metadata:** commit `docs(46-03)` de ce SUMMARY (le suivant dans l'historique).

Tracer vérifié de bout en bout avant l'expansion : les deux `<automated>` de la Tâche 1 au vert sur l'arbre commité (392 OK ; `g1,banc` 222 OK), puis expansion. La Tâche 1 a été commitée avec le cache v1 encore en place (le bloc de cache de la Tâche 2 était tenu hors du commit), pour que chaque commit soit vert à lui seul.

## Inventaire des fixtures de verdict et leur traitement (étape 1 de la Tâche 1)

Relevé par recherche textuelle avant toute modification de R4.

| Suite / fixture | Verdicts ou `ecrit:` | Traitement |
|---|---|---|
| `recalc-planning-banc.txt` | 15 fixtures `VERDICT.md` | **13 verdicts valides à résoudre**, convertis aux jetons : `traceur`, `traceur-gsd`, `traceur-gsd-partition`, `etat-a-corriger` (échec), `etat-a-corriger-jumeau` (passé), `etat-close`, `etat-close-jumeau` (échec + SUMMARY), `d08-summary-verdict-echec`, `plans-agregation` (plan `01-a`), `plans-tous-clos` (plans `01-a` et `02-b`, ce dernier à hash littéral différent), `cycle-close`, `cycle-propagation`. **2 verdicts non lus par R6, laissés littéraux** : `d08-verdict-sans-marqueur` (R3 précède), verdict au niveau phase d'un lab à `plans/` (Φ5 précède). Aucun verdict n'est « volontairement périmé » dans le banc d'origine. |
| `recalc-planning-banc.txt` | livrables vides ou liés | **0 fichier vide, 0 lien de livrable** avant ce plan (Pitfall 3 confirmé) ; ils sont créés exprès par les nouveaux labs `livrable-vide`, `livrable-lien`, `livrable-dossier-vide`, `livrable-dossier-ds-store`. |
| `recalc-planning-banc.txt` | l.577 `indéterminé :: verdict-passe-sans-SUMMARY.md` | attendu changé en `à clore` (phase et agrégat du cycle). |
| `test-recalc-planning.sh` | 4 écritures en ligne d'un verdict à hash littéral dont le test dérive `close` (journal) : `R-INJECTIF-ROUNDTRIP` (deux écritures), `R-DEDOUBLONNAGE-ASSAINI`, `MUT-DEDOUBLONNAGE-BRUT` | **verdicts valides à résoudre** : jetons + nouvelle aide `jetons` après chaque écriture (sans quoi ils devenaient `indéterminé` : 4 rouges mesurés avant correction). |
| `test-recalc-planning.sh` | `R23-C` (gabarit `VERDICT.template.md` → `verdict-invalide`) ; `R53` et `MUT-SIGNATURE-TEMPS` (échange `passé` → `échec` à taille égale sur un verdict de `traceur`) | `R23-C` : R6, inchangé. `R53` et la signature : le verdict de `traceur` est résolu, l'échange à taille égale conserve les deux empreintes : inchangés. |
| `test-planning-gates.sh` | aucun verdict écrit à la main ; les verdicts de `R-VERDICT-*` et `lota` sont posés par la vraie `poser-verdict.sh` (valides aux deux empreintes, `R-VERDICT-03` attend `close`) | inchangés ; seule modification : le matérialiseur du banc lit les jetons du banc de recalcul (contrôle croisé de G1, `BANC_RECALC`), sans quoi les verdicts du banc y deviendraient périmés. |
| `gates-banc.txt` | 0 fichier `VERDICT.md` (seulement des cibles `@@ ecriture … VERDICT.md`) ; 11 marqueurs de code G7 vides sous `zone/`, dossier `zone` rendu non vide par `zone/cible/fichier.txt` | inchangé (aucun verdict à résoudre, aucun livrable qui change d'état). |
| `test-rejeu-gates.sh` | `VERDICT.md` n'y est qu'une cible d'écriture ; `ecrit: livrables/a.md` de labs synthétiques | inchangé, vert (91 OK). |

## Mutants (trace du rouge : assertion, attendu, obtenu)

| Mutant | Motif unique (balise) | Assertion | Attendu (original) | Obtenu (mutant) |
|---|---|---|---|---|
| MUT-R4-VIDE | `# r4-predicat` : prédicat remplacé par `os.path.lexists` | état/raison du lab `livrable-vide` | `indéterminé|livrable-vide:livrables/rapport.md` | `à juger|` (R5 : le livrable de 0 octet est « présent ») |
| MUT-EMPREINTES-RECALC | `if perime:` → `if False:` (règle E neutralisée) | état/raison du lab `verdict-perime` | `à juger|verdict-perime` | `à clore|` |
| MUT-A-CLORE | `# r8-a-clore` : R8 rend l'ancien `indéterminé` | état/raison du lab `etat-a-clore` | `à clore|` | `indéterminé|verdict-passe-sans-SUMMARY.md` |
| MUT-LIVRABLES (existant, réorienté) | `# r4-predicat` : R4 neutralisé | état du lab `etat-a-juger-jumeau` | `indéterminé` (`livrable-absent`) | `à juger` |
| MUT-LIVRABLES-CACHE (existant, réécrit) | `# cache-empreinte` → `if True:` | R58 (livrable supprimé) **et** R-CACHE2-01 (un octet réécrit) | `indéterminé` (livrable absent), puis `indéterminé` (livrable ou plan modifié après la clôture) | la ligne d'index reste `à exécuter \| 02-en-cours` : le `close` en cache n'est pas rejugé dans les deux scénarios |

Chaque mutant est refusé s'il plante (`_verifier_plantage`, ou `ERREUR` du lecteur d'état) : aucun n'est « tué » par une fixture morte ; les témoins non mutés des mêmes lectures sont verts dans la même exécution.

## Files Created/Modified

- `plugin/planning-core/scripts/recalc-planning.sh` - R4 par `livrable_present`, règle E, état `à clore`, cache v2 (`_livrables_pour_cache`), `LIBELLES`, `_meta_unite` (`hash_livrables`), `_raison_a_juger`, rendu de la raison d'un `à juger` périmé.
- `plugin/planning-core/scripts/tests/test-recalc-planning.sh` - résolution des jetons, aide `jetons`, R20 à douze états, R27 réécrit, R-CLORE-01, R-PERIME-01 et 02, R-R4VIDE-01, R-JETON-01, R-CACHE2-01 et 02, trois mutants neufs, deux mutants réécrits.
- `plugin/planning-core/scripts/tests/fixtures/recalc-planning-banc.txt` - treize verdicts aux jetons, l'attendu de `etat-a-corriger-jumeau`, dix-huit labs neufs (neuf et leur jumeau), en-tête des jetons.
- `plugin/planning-core/scripts/tests/test-planning-gates.sh` - matérialiseur du banc : résolution des mêmes jetons par la même règle.
- `plugin/planning-core/references/modele-cycles.md`, `plugin/planning-core/references/templates/cycles/VERDICT.template.md` - voir Task 3.

## Decisions Made

Voir `key-decisions`. Les décisions de discrétion annoncées par le plan (balises, codes de raison, ordre des règles, clé de cache) sont appliquées telles quelles. Précisions prises à l'exécution (renversables) : R4 rend `livrable-absent` pour un livrable illisible (aucun code nouveau) ; le libellé de `verdict-perime` garde le « n+1 » littéral du plan ; la valeur de cache est un état comparable et non une empreinte seule (écart 1).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Règle de cache « un statut d'empreinte autre que ok invalide l'entrée » rendait R51 et R52 rouges**
- **Found during:** Task 2 (suite du recalcul, premier passage avec le cache v2 : R51 « unites_reprises = unites » et R52 « unites_recalculees 0 » rouges)
- **Issue :** appliquée à la lettre, la règle ne reprenait jamais une unité dont les livrables ne sont pas (encore) présents (`02-en-cours` du lab `traceur`), alors que R51 et R52 (existants) exigent cette reprise ; le plan interdit d'affaiblir un cas existant.
- **Fix :** la valeur de cache est comparable : `["ok", empreinte]` quand tous les livrables sont présents, `["statuts", {entrée: statut}]` quand l'un est absent, vide ou lien (la dérivation ne dépend alors que de ces statuts, pas du contenu), `None` quand l'empreinte échoue alors que tous les livrables sont présents (borne, lecture impossible) : jamais reprise. L'esprit de la règle tient : aucune entrée n'est reprise sur une empreinte ou un état de livrables qui a changé, et un échec de calcul de l'empreinte n'est jamais repris. Le choix d'une carte de statuts par entrée (et non du seul premier statut en échec) évite un cache périmé quand R4 nomme une autre entrée que la première fautive.
- **Files modified:** plugin/planning-core/scripts/recalc-planning.sh
- **Verification:** R51, R52, R58, R-CACHE2-01, R-CACHE2-02, MUT-LIVRABLES-CACHE verts (398 OK, 0 KO)
- **Committed in:** b196b62d

**2. [Rule 1 - Bug] MUT-LIVRABLES (R4 neutralisé) ciblait une ligne que R4 n'a plus**
- **Found during:** Task 1 (`✗ MUT-LIVRABLES NON TUÉ`, motif absent)
- **Issue :** le plan ne cite que MUT-LIVRABLES-CACHE ; MUT-LIVRABLES visait `manquant = next(...)`, ligne remplacée par l'appel du prédicat.
- **Fix :** réorienté sur la ligne `# r4-predicat` (neutralisation de R4 : `statut_livrable = "present"`), même cas de test.
- **Files modified:** plugin/planning-core/scripts/tests/test-recalc-planning.sh
- **Verification:** `✓ MUT-LIVRABLES TUÉ` (original `indéterminé`, mutant `à juger`)
- **Committed in:** dc579231

**3. [Rule 1 - Bug] Quatre verdicts écrits en ligne à hash littéral devenaient périmés**
- **Found during:** Task 1 (R-INJECTIF-ROUNDTRIP, R-DEDOUBLONNAGE-ASSAINI, MUT-DEDOUBLONNAGE-BRUT : le journal n'écrivait plus rien, l'unité n'étant plus `close`)
- **Issue :** ces cas posent un verdict valide à la main pour exercer le journal ; la règle E le rend périmé.
- **Fix :** jetons dans le verdict écrit, puis aide `jetons <lab>` (même résolveur que le banc). Aucun cas retiré ni affaibli.
- **Files modified:** plugin/planning-core/scripts/tests/test-recalc-planning.sh
- **Verification:** les trois cas verts (392 OK à la Tâche 1)
- **Committed in:** dc579231

### Choix du plan appliqués avec une précision

- La raison d'un `à juger` périmé n'était rendue nulle part : au-delà de `_texte_etat_cycle`, la raison est désormais remontée du plan à la phase (`_agreger_plans`) et au cycle (`deriver_cycle`) par `_raison_a_juger`, sans quoi l'index n'aurait rien à rendre. Aucun état ni raison existant ne change (une raison n'existait que pour `indéterminé`).
- Le « jumeau dev » du plan (R-CLORE-01, R-R4VIDE-01) est, dans ce banc, un jumeau de dérivation `jumeau-de=` (R20 l'exige) : même unité, autre état. Le silence hors adhésion appartient au hook, pas au recalcul en lecture seule.
- `gates-banc.txt` et `test-rejeu-gates.sh`, listés dans `files_modified`, n'ont **pas** été modifiés : l'inventaire n'y relève aucune fixture qui dérive autrement ; les deux suites sont vertes.

### Adaptations de protocole (mandat)

- La garde d'isolation a refusé une première commande inline (script Python fourni en heredoc dans un appel Bash) : « this command is too complex to verify that it stays inside the worktree ». Elle n'a pas été contournée : le même script a été écrit dans le scratchpad puis lancé en `python3 <fichier>`, forme prescrite par le mandat. Même traitement pour les commandes `<automated>` (fichiers puis `bash <fichier>`).
- La base du plan (`c60d56f1…`, HEAD au dispatch) est inscrite dans `plan_head_before`, `commits: 3` est mesuré par `git rev-list --count` (le registre de base du protocole n'a pas été écrit, comme en 46-01).
- L'assertion « branche `agent-*` » n'a pas été appliquée (branche de mission `gouvernance/phase-46-execution`, non protégée, exécution sans isolation par worktree d'agent).
- La suite complète `test-planning-gates.sh` (716 s sous une charge machine d'environ 25) a dépassé les 600 s : le harnais l'a basculée en arrière-plan, sans choix de ma part ; elle a fini en code 0 (461 OK, 0 KO).

## Issues Encountered

- Rouge d'une suite hors périmètre : aucun. `test-planning-hook-registered.sh` (R-DOUTE-03, rouge temporel connu à la base) n'est pas nommé par ce plan et n'a pas été rejoué.
- Rien de différé.

## Known Stubs

None.

## Threat Flags

None. Le plan couvre le seul franchissement de frontière touché (disque du lab vers recalcul) ; T-46-031 est mitigé (règle E, cache v2, R-PERIME-02, R-CACHE2-01, MUT-EMPREINTES-RECALC, MUT-LIVRABLES-CACHE), T-46-032 par l'exigence de `hash_livrables` (R-PERIME-01, clé absente), T-46-033 par le prédicat partagé (R-R4VIDE-01, lien = absent), T-46-034 est accepté (coût déclaré dans `modele-cycles.md`).

## Résultats des vérifications automatisées (code de sortie)

| Vérification | Résultat |
|---|---|
| T1 `test-recalc-planning.sh` (les cinq contrôles awk du plan, dont douze états et les trois mutants) | 0 (392 OK, 0 KO) |
| T1 `VF_GATES_SECTIONS=g1,banc test-planning-gates.sh` | 0 (222 OK, 0 KO) |
| T1 critère d'acceptation : `awk '/verdict-passe-sans-SUMMARY/'` sur le script et le banc | 0 ligne |
| T2 `test-recalc-planning.sh` (R-CACHE2-01 et 02, R58, MUT-LIVRABLES-CACHE) | 0 (398 OK, 0 KO) |
| T2 `test-planning-gates.sh` entière | 0 (461 OK, 0 KO, 716 s) |
| T2 `test-rejeu-gates.sh` | 0 (91 OK, 0 KO, 340 s) |
| T2 critère d'acceptation : `awk '/^CACHE_SCHEMA_VERSION = 2/'` | une ligne |
| `test-cloture-empreintes.sh` (R-EMP-04 : copies ast-identiques intactes) | 0 (23 OK, 0 KO) |
| T3 `awk` du plan sur `modele-cycles.md` (titre « Les neuf états », `à clore` au moins trois fois, deux motifs) | 0 |
| T3 `VF_GATES_SECTIONS=reference test-planning-gates.sh` | 0 (18 OK, 0 KO) |
| T3 critère d'acceptation : `awk '/jamais vérifiés/'` sur `VERDICT.template.md` | 0 ligne |
| `scripts/check-machine-paths.sh` | 0 |
| contrôle du marqueur (`45-CONTROLE-MARQUEUR.sh --base=247194c7 -- plugin/planning-core/scripts plugin/planning-core/hooks`) | 0 (`sans-marqueur=0`) |

## Next Phase Readiness

- Le recalcul dérive neuf états et vérifie les deux empreintes de tout verdict : G4 (46-05) peut refuser l'écriture de `SUMMARY.md` sur le même critère, avec la même copie du bloc ; `rejeu-gates.sh` classe déjà tout état autre qu'`indéterminé` comme « fait référence » (aucune modification requise pour `à clore`).
- Rien n'est armé. Les plans suivants qui ajoutent des noms à la racine de `.planning/` (46-07, 46-09) étendent `NOMS_MODELE_RACINE_*` dans ce même script.

---
*Phase: 46-moteur-gates-de-cl-ture-et-verdicts-hach-s*
*Completed: 2026-10-03*

## Self-Check: PASSED

- Fichiers modifiés présents ; aucun fichier créé hors ce SUMMARY.
- Commits présents : `dc579231`, `b196b62d`, `dad32f8e` (`git log --oneline`).
- Aucune modification de STATE.md, ROADMAP.md ni REQUIREMENTS.md ; fichier suivi `.planning/missions/2026-10-03-gouvernance-46-exec.dag.json` modifié avant ce plan, non stagé.
