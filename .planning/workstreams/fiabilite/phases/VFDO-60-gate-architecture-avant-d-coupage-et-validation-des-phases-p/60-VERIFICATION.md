---
phase: 60-gate-architecture-avant-d-coupage-et-validation-des-phases-p
verified: 2026-10-29T15:00:00Z
status: human_needed
score: 6/11 must-haves verified
covered_files:
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-01-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-01-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-02-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-02-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-03-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-03-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-04-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-04-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-05-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-05-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-06-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-06-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-07-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-07-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-08-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-08-SUMMARY.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-09-PLAN.md
  - .planning/workstreams/fiabilite/phases/VFDO-60-gate-architecture-avant-d-coupage-et-validation-des-phases-p/60-09-SUMMARY.md
  - plugin/conductor/scripts/check-architecture.sh
  - plugin/conductor/scripts/check-phase-validation.sh
  - plugin/conductor/scripts/vf-validation.sh
  - plugin/dev-orchestrator/agents/vf-coder.md
  - plugin/dev-orchestrator/references/product-routing.md
  - plugin/dev-orchestrator/skills/vf-auto/SKILL.md
  - plugin/planning-core/references/templates/product/ARCHITECTURE.template.md
  - plugin/product-team-bundle/agents/vf-product-architect.md
covered_digest: "v4:sha256:5ebcf120d962e1839ab5fc24fe68a8fb9aaa42ec11f373f8dac220660e3b8724"
behavior_unverified: 4
overrides_applied: 0
behavior_unverified_items:
  - truth: "ARCG-03 — avant gsd-plan-phase et gsd-execute-phase, vf-coder constate le marqueur ; phase proposée -> rapport blocked + finding ask-user, aucune brique lancée"
    test: "Dispatcher vf-coder sur un lab dont l'étape N porte `**Validation:** proposed`, mandat avec numéro d'étape"
    expected: "Rapport typé `blocked` + `action: ask-user` nommant `vf-validation.sh validate --phase N` ; ni gsd-plan-phase ni gsd-execute-phase lancés"
    why_human: "C'est un ordre d'exécution d'un agent LLM. Seuls sont prouvés le texte ancré (T45 a, mutants discriminants) et l'exécution de la commande citée sur fixture (rc 1 / rc 0). Aucun test ne fait agir vf-coder."
  - truth: "ARCG-04 — vf-auto refuse de lancer le moteur direct gsd-autonomous sur une étape proposée (étape 0 bis)"
    test: "Lancer /vf-auto en mission courte sur une étape dont le marqueur est `proposed`"
    expected: "Le moteur direct ne démarre pas ; une phrase le dit et une question propose de valider ou de réduire le périmètre"
    why_human: "Même nature : texte de SKILL.md ancré et commande citée exécutée, jamais un run de vf-auto. Limite écrite : étape ajoutée pendant la boucle non interceptée."
  - truth: "ARCG-05 — le head consulte check-architecture.sh devant une intention de découpage (postes product/dev, BRIEF.md présent), s'arrête, exécute sur demande réitérée avec override tracé ; solo non consulté"
    test: "Au poste dev, lab avec BRIEF.md et ARCHITECTURE.md absente ou proposée : demander « ajoute une étape »"
    expected: "Une phrase de motif puis halte ; réitérer explicitement exécute et trace l'override ; au poste solo, aucune consultation"
    why_human: "Comportement du head (agent) : preuve par texte ancré de la §5 de product-routing.md et liens vérifiés (T45 d, e, f), aucun run. Les hypothèses P60-H-01 à P60-H-04 sont à confirmer par Samuel."
  - truth: "ARCG-01 (volet pose) — une phase ajoutée par l'équipe au poste product ou dev naît proposée, aucune au poste solo"
    test: "Mission réelle de vf-dev-manager au poste dev avec brief `Phases ajoutées : proposées`, ajout d'une phase par gsd-phase"
    expected: "`vf-validation.sh propose --phase N` joué par le manager ; le ROADMAP porte `**Validation:** proposed` sur la phase créée ; au poste solo, aucun marqueur"
    why_human: "Chaîne head -> champ de brief -> manager -> verbe : prouvée par le texte et le lien manager->contrat (T45 c), jamais par une exécution de mission. Dette nommée P60-PL-26."
human_verification:
  - test: "Run réel du flux d'équipe sur un lab désigné (vf-coder, vf-auto, head, manager ; worker vf-product-architect)"
    expected: "Voir behavior_unverified_items (ARCG-01 pose, ARCG-03, ARCG-04, ARCG-05) ; le worker produit une ARCHITECTURE.md `proposed` complète que `check-architecture.sh` rend code 1 avec `rubriques_manquantes=0`"
    why_human: "Agents LLM : aucun test ne les fait agir ; geste humain de P59-D-11, condition de `proposable:true` du bundle."
  - test: "Fournir la liste de noms de clients (hors dépôt) puis rejouer `check-livraison-58.sh clients --base 2649ccd4`"
    expected: "Code 0 (zéro nom de client) ; alors ARCG-09 peut être cochée"
    why_human: "Mesuré par moi : code 2 NON-VÉRIFIABLE (liste absente). Un code 2 n'est jamais un vert (précédent RLPO-11)."
  - test: "Confirmer ou infirmer P60-H-01 à P60-H-04, O-8 et P60-PL-06"
    expected: "Décision de Samuel (canal et date tracés)"
    why_human: "Hypothèses retenues faute de réponse humaine : le cadrage de la phase dit explicitement qu'aucune n'est un arbitrage."
  - test: "Décider du standard de preuve des ARCG-03/04/05 cochées : accepter le texte ancré, ou exiger un run avant de les garder cochées"
    expected: "Décision de Samuel"
    why_human: "Incohérence de ledger relevée : ARCG-01 est Partial faute de run réel, alors que ARCG-03/04/05 (même nature de preuve, sans run) sont Complete. Chaque ligne du ledger dit « aucun run réel » : honnête, mais le seuil n'est pas uniforme."
warnings:
  - finding: "check-phase-validation.sh : la clause de fermeture de section (`if (insec && lvl <= seclvl) insec = 0`) peut être supprimée ou affaiblie sans qu'aucun des 46 cas ni des 10 mutants ne rougisse"
    reason: "Mesuré en mutant : un ROADMAP dont la phase 3 est `proposed` et la phase 2 sans marqueur rend, sur le mutant, `--phase 2` -> code 1 `proposee` au lieu de code 0. Le cas CPV-TRACE-2 dit tester que « le marqueur de la phase 2 ne déborde pas sur la phase 3 » mais interroge la phase 3 avec un marqueur en phase 2 : c'est l'autre sens, que la construction du gate rend toujours vrai. Le comportement livré est correct (rejoué : original rc 0, mutant rc 1) ; c'est une lacune de test, dans la direction fail-closed (faux refus), pas un trou de sécurité. Le même mutant est tué dans test-vf-validation.sh (VFV-SANS-GOAL)."
    harden: "Ajouter à probe_trace2 ou à un cas dédié : phase 2 sans marqueur, phase 3 `proposed`, `--phase 2` attendu rc 0 ; en faire un mutant CPV-MUT-11."
    severity: warning
  - finding: "Parité mawk (A1) non rejouée par l'exécutant (démon Docker arrêté) ; mes rejeux ont tourné sous l'awk de macOS seulement"
    reason: "Les gates reposent sur de l'awk (gsub avec octets, ENVIRON, index) ; la CI Linux de la PR en est le témoin, comme le dit 60-09-SUMMARY."
    harden: "Lire le résultat du job CI de la PR avant merge."
    severity: warning
---

# Phase 60 : Gate architecture avant découpage et validation des phases proposées, rapport de vérification

**Phase Goal :** Un gate séparé assemble l'existant (`software-architecture`, GSD). Le head refuse le découpage en phases tant que `ARCHITECTURE.md` n'est pas validée (A-08). Une phase ajoutée par le rôle product ou par le head reste proposée jusqu'à sa validation par un dev ; en solo, elle est auto-validée. Le mécanisme passe par un marqueur sur la phase et `check-phase-validation.sh` (A-07).
**Verified :** 2026-10-29
**Status :** human_needed
**Re-verification :** Non, vérification initiale (aucun `60-VERIFICATION.md` antérieur)
**Base de phase :** `2649ccd4` ; pointe vérifiée : `b4a6b581` (branche `feat/phase-60-gate-architecture`)

## Verdict en deux phrases

Les mécanismes déterministes (le marqueur, les deux gates, l'écrivain `vf-validation.sh`, le gabarit, le worker, le câblage textuel) existent, sont substantiels et rejoués verts, et les mutants du plan sont réellement discriminants sauf une lacune relevée (warning). Ce qui reste non prouvé est ce qu'aucun test ne peut atteindre, le comportement des agents (refus de `vf-coder`, de `vf-auto`, du head, pose par le manager), ce que le ledger dit déjà ; deux exigences (ARCG-01, ARCG-09) sont correctement laissées partielles.

## Goal Achievement

### Observable Truths

Les vérités sont les onze exigences ARCG (le ROADMAP de la phase n'a pas de liste de critères de succès propre : il porte le But et `Requirements`).

| # | Vérité | Statut | Preuve |
|---|--------|--------|--------|
| 1 | ARCG-01 marqueur de phase (forme, absent = validée, lecteurs GSD inchangés, verbe de script, limite fail-open écrite) ; **volet pose par l'équipe** | PRESENT_BEHAVIOR_UNVERIFIED (partiel, correct) | Marqueur `**Validation:**` lu par `check-phase-validation.sh` ; `CPV-GSD-NEG/GET/ANALYZE/WS/COMPLETE/RENUM` verts (46 ok, 0 skip) ; `test-vf-validation.sh` 35 ok dont `VFV-GSD-PROPOSE/VALIDATE` ; verbe `vf-validation.sh` sans skill neuf ; limite fail-open écrite dans les en-têtes des scripts et dans `product-routing.md` §5. Pose « proposée » par le manager : texte (`mission-contracts.md` §Champ `Phases ajoutées`, `intent-routing.md`) seulement. |
| 2 | ARCG-02 `check-phase-validation.sh` : conductor, lecture seule, forme exec, `--ws` explicite, codes 0/1/3/5/64, ne lit pas le poste, trois issues, mutants, recensé, trailers | ✓ VERIFIED (avec warning de test) | Script lu en entier ; `test-check-phase-validation.sh` 46 ok / 0 ko ; recensé (`workstream-planning-consumers.md:77`, `check-planning-consumers-registered.sh` rc 0, 24 consommateurs) ; trailers `Gate-Touche` présents sur les commits qui touchent le script et sa suite (lus dans le journal) ; `Ajout-Retrait` -> `check-ajout-retrait.sh --strict --base-ref 2649ccd4` rc 0 `AJOUT-COUVERT`. Mes mutants : `tolower` retiré, suffixe `validated` permissif, BOM : tués ; fermeture de section : SURVIT (warning 1). |
| 3 | ARCG-03 refus par `vf-coder` avant plan et exécution ; `vf-dev-manager` inchangé | PRESENT_BEHAVIOR_UNVERIFIED | `vf-coder.md` §Porte « phase proposée » placée avant `## Le cycle`, codes 0/1/3-5-64, `blocked` + `ask-user` ; `vf-dev-manager.md` : diff vide contre `2649ccd4`. T45 (a) joue la commande citée sur fixture (rc 1 / rc 0). Mes mutants de texte (code 1 -> 0) : tués par T45 (a). Aucun run de l'agent. |
| 4 | ARCG-04 chemin direct `vf-auto` | PRESENT_BEHAVIOR_UNVERIFIED | `SKILL.md` §Étape 0 bis ; mon mutant « démarre quand même » tué par T45 (b). Aucun run. |
| 5 | ARCG-05 découpage avant architecture, consulté par le head | PRESENT_BEHAVIOR_UNVERIFIED | `product-routing.md` §5 (poste via `vf-role.sh get`, codes 1/5/64 jamais repliés, BRIEF.md, override tracé), ligne-pointeur dans `AGENT.md` sans ligne ajoutée (216 = 216). Mes mutants (BRIEF existe -> est absent ; solo -> gate s'applique) tués par T45 (e). Aucun run du head. |
| 6 | ARCG-06 `.planning/ARCHITECTURE.md` décisionnel, gabarit planning-core, état dans le fichier | ✓ VERIFIED | `ARCHITECTURE.template.md` (six rubriques, ligne d'état `proposed`, distingue les trois fichiers homonymes) ; `vf-validation.sh validate --architecture` ; planning-core 2.9.0 -> 2.10.0 ; le gabarit brut est rouge par construction (`CARCH-TRACE-1` : code 1, six rubriques vides). |
| 7 | ARCG-07 gate architecture séparé, trois issues, mutants | ✓ VERIFIED | `check-architecture.sh` lu ; 34 ok / 0 ko, 9 mutants tués ; mes 8 mutants indépendants (tbd, todo, crochet de tête, corps sans lettre, rubrique `donn`, `body==0`, suffixe `validated`, fermeture de rubrique) : tous tués. |
| 8 | ARCG-08 worker `vf-product-architect` interne, allowlist, ≤ 250 lignes, strict, une ligne de baseline | ✓ VERIFIED (structure) | 81 lignes, `vf-internal: true`, outils `Read, Write, Edit, Glob, Grep` (pas de Bash : il ne peut lancer ni gate ni verbe de validation) ; `Agent(... vf-product-architect ...)` dans `vf-product-manager.md` ; `check-agents.sh --strict --manifest-freshness=strict` sur chaque `plugin/*/agents` : 0 échec ; monde fermé `--resolve-agents=strict` : 0 échec ; `test-product-team-bundle.sh` 104 ok / 0 ko. La qualité de ce que l'agent rédige n'est pas exercée (aucun run). |
| 9 | ARCG-09 sobriété : aucune valeur de baseline relevée, budget vert, aucun skill neuf, zéro nom de client, gates avec trois issues et mutation, `Ajout-Retrait` | UNCERTAIN (partiel, correct) | Voir Probe ci-dessous : 1 ajout / 0 retrait / 0 valeur relevée ; budget rc 0 ; 0 SKILL.md neuf ; `Ajout-Retrait` conforme. Critère 6 `clients` : code 2 NON-VÉRIFIABLE, mesuré par moi. |
| 10 | ARCG-10 manuel FR et EN | ✓ VERIFIED | `check-manual.sh` rc 0 (« tous les contrôles passent ») ; 16 pages FR + EN modifiées en nombre égal, `gates-et-validation-humaine.md` / `gates-and-human-validation.md` portent la section « avant le découpage ». |
| 11 | ARCG-11 livraison : porte rejouée, ledger à la main, arrêt avant PR/merge/tag/release, bumps de modules | ✓ VERIFIED | `VERSION` racine, manifestes de plugin, `.github/`, `scripts/` : diff vide ; aucun tag sur HEAD ; bumps conductor 1.50.2 -> 1.51.0, dev-orchestrator 2.29.0 -> 2.30.0, product-team-bundle 1.0.0 -> 1.1.0, planning-core 2.9.0 -> 2.10.0 (valeurs lues dans le diff des `VERSION`), `check-version-sync.sh` rc 0 (v2.72.0, 18 modules, 116 suites). La porte complète n'a pas été rejouée par moi (consigne) ; ses composants l'ont été (voir Spot-checks). |

**Score :** 6/11 vérités vérifiées ; 4 présentes et câblées mais comportement non exercé (`behavior_unverified: 4`, dont ARCG-01 partielle) ; 1 incertaine (ARCG-09, critère 6). Aucune vérité FAILED.

### Contrôles demandés

| # | Contrôle | Résultat |
|---|----------|----------|
| 1 | Cases ARCG justifiées ; ARCG-01 et ARCG-09 correctement Partial | **ARCG-02, 06, 07, 08, 10, 11 : cases justifiées.** ARCG-01 et ARCG-09 : Partial **correct**, pour les raisons que j'ai moi-même retrouvées (pose non prouvée ; code 2 mesuré). **ARCG-03, 04, 05 : cochées sur un texte ancré et des commandes exécutées, jamais sur un run** ; le ledger le dit sur chaque ligne, mais le seuil diffère de celui appliqué à ARCG-01 (voir `human_verification` n°4). Je ne demande pas de les décocher, je demande une décision. |
| 2 | Baseline : exactement +1 ligne, aucune valeur relevée | **CONFORME.** `git diff 2649ccd4 HEAD -- .planning/instruction-budget-baselines.tsv` : 1 ligne ajoutée (`plugin/product-team-bundle/agents/vf-product-architect.md	81	17`), 0 retirée, 0 modifiée (comptage des lignes `+`/`-` hors en-têtes : 1). `vf-coder.md` passe de 122 à 157 lignes mais sa valeur d'instructions reste 22 pour une baseline de 23 (statut `MARGE+LIGNES-EN-HAUSSE`, rc 0 : le ratchet porte sur les instructions seules, ADR-029 révisée). |
| 3 | `check-prd.sh` inchangé | **CONFORME.** `git diff 2649ccd4 -- plugin/product-team-bundle/scripts/check-prd.sh` : 0 ligne ; sa suite `test-check-prd.sh` non listée dans le diff. |
| 4 | Aucun skill ajouté ; rien dans `scripts/hooks/`, `.github/`, `.planning/*-armed` | **CONFORME.** `--name-status` : aucun `A` sur un `SKILL.md` (deux `M` : `vf-auto` +15 lignes, `vf-product` +1) ; diff vide sur `scripts`, `.github` ; aucun fichier `*-armed` dans le diff. |
| 5 | Mutants discriminants | **Oui pour `check-architecture.sh`, `vf-validation.sh` et T45 ; une lacune pour `check-phase-validation.sh`** (warning 1). Méthode : copie jetable de `plugin/`, mutation par `perl`, suite complète rejouée, échecs hors `MUT-*` listés. |

## Mutation indépendante (mes mutants, copies jetables hors dépôt)

| Gate | Mutant | Résultat |
|------|--------|----------|
| check-phase-validation | suffixe `validated` quelconque accepté | tué (CPV-VALIDATED) |
| check-phase-validation | `tolower` retiré | tué (CPV-VALIDATED) |
| check-phase-validation | BOM non retiré | tué (CPV-BOM) |
| check-phase-validation | **fermeture de section retirée / `<=` -> `<`** | **SURVIT** (warning 1 ; effet réel rejoué : faux code 1 sur la phase 2) |
| check-phase-validation | `bump 1` sans garde du code 5 ; CR non retiré par `sed` | survivants équivalents (le code 5 est rendu avant tout awk ; `tr` retire aussi le CR) |
| check-architecture | tbd, todo, `[` de tête, corps sans lettre, rubrique `donn`, `body==0`, suffixe `validated`, fermeture de rubrique | 8/8 tués |
| vf-validation | refus du poste `product` retiré ; `propose` sur `validated` ; fermeture de section ; marqueur après Goal multi-lignes | 4/4 tués |
| vf-validation | `if [ "$rrc" -ne 0 ]` neutralisé | survivant équivalent (la branche `*)` du `case` refuse déjà un poste vide : défense en profondeur) |
| T45 (dev-orchestrator) | code 1 -> 0 dans `vf-coder` ; « ne démarre pas » -> « démarre quand même » dans `vf-auto` ; BRIEF existe -> absent ; solo -> gate s'applique ; champ de brief réduit au poste solo | 5/5 tués par T45 (a), (b), (e), (c) |

Les mutants de T45 portent sur des ancres de texte : ils prouvent que le texte ne peut pas dériver en silence, pas que l'agent s'y conforme.

## Required Artifacts

| Artefact | Attendu | Statut | Détails |
|----------|---------|--------|---------|
| `plugin/conductor/scripts/check-phase-validation.sh` | gate du marqueur, 268 lignes | ✓ VERIFIED | Lu en entier ; lecture seule ; pas de `eval` ; rejoué via sa suite |
| `plugin/conductor/scripts/check-architecture.sh` | gate d'architecture, 268 lignes | ✓ VERIFIED | idem |
| `plugin/conductor/scripts/vf-validation.sh` | seul écrivain du marqueur, 292 lignes | ✓ VERIFIED | Écriture atomique, poste lu par `vf-role.sh get`, jamais de repli sur `solo` |
| trois suites `test-check-phase-validation.sh`, `test-check-architecture.sh`, `test-vf-validation.sh` | cas et mutants | ✓ VERIFIED | 46 / 34 / 35 ok, 0 ko, 0 skip ; fixtures écrites à l'exécution |
| `plugin/planning-core/references/templates/product/ARCHITECTURE.template.md` | gabarit décisionnel | ✓ VERIFIED | six rubriques, état `proposed` |
| `plugin/product-team-bundle/agents/vf-product-architect.md` | worker interne | ✓ VERIFIED | voir ARCG-08 |
| `plugin/dev-orchestrator/{agents/vf-coder.md, skills/vf-auto/SKILL.md, references/product-routing.md, mission-contracts.md, AGENT.md}` | refus et §5 | ✓ VERIFIED (texte) | câblés ; comportement non exercé |

## Key Link Verification

| De | Vers | Via | Statut | Détails |
|----|------|-----|--------|---------|
| `vf-coder.md` | `check-phase-validation.sh` | commande citée, `$S` résolu comme en `mission-flow.md` | WIRED | T45 (a) exécution et (f) liens verts |
| `vf-auto/SKILL.md` | `check-phase-validation.sh` | étape 0 bis | WIRED | T45 (b), (f) |
| `product-routing.md` §5 | `check-architecture.sh`, `vf-role.sh`, `vf-validation.sh` | commandes citées | WIRED | T45 (e), (f) ; `AGENT.md` pointe vers la §5 sur la même ligne |
| `mission-contracts.md` champ `Phases ajoutées` | `vf-dev-manager` -> `vf-validation.sh propose` | texte | PARTIAL | Lien de texte vérifié (T45 c) ; le manager n'a pas été modifié et aucune exécution ne montre qu'il pose le marqueur |
| `vf-product-manager.md` | `vf-product-architect` | `Agent(...)`, livrable `architecture`, contrôle `check-architecture.sh` code 1 attendu | WIRED | monde fermé vert |
| `check-phase-validation.sh`, `vf-validation.sh` | `workstream-policy.sh` | `vf_ws_name_valid`, `vf_ws_dir_resolve` | WIRED | recensés dans `workstream-planning-consumers.md` |

## Data-Flow Trace (Level 4)

Non applicable aux gates (pas de rendu). Flux marqueur : `vf-validation.sh` écrit une ligne ; `check-phase-validation.sh` la lit avec la même grammaire (awk repris à l'identique) ; le moteur GSD ignore le champ (CPV-GSD-*). Vérifié par exécution, FLOWING.

## Behavioral Spot-Checks

| Comportement | Commande | Résultat | Statut |
|--------------|----------|----------|--------|
| marqueur et gate | `bash plugin/conductor/scripts/tests/test-check-phase-validation.sh` | 46 ok / 0 ko | ✓ PASS |
| gate d'architecture | `... test-check-architecture.sh` | 34 / 0 | ✓ PASS |
| écrivain | `... test-vf-validation.sh` | 35 / 0 | ✓ PASS |
| bundle produit | `... test-product-team-bundle.sh` | 104 / 0 | ✓ PASS |
| dev-orchestrator (T45) | `... test-dev-orchestrator.sh` | 398 / 0 | ✓ PASS |
| budget d'instructions | `check-instruction-budget.sh` | rc 0, BOOTSTRAP 2610 inchangé (au-dessus du plafond, préexistant) | ✓ PASS |
| agents, trois formes CI | `check-agents.sh --strict ...` (par `plugin/*/agents`, fermé) | 0 échec | ✓ PASS |
| sobriété d'ajout | `check-ajout-retrait.sh --strict --base-ref 2649ccd4` | rc 0, 2 ajouts couverts | ✓ PASS |
| versions, manuel, état, consommateurs | `check-version-sync.sh`, `check-manual.sh`, `check-state-integrity.sh`, `check-planning-consumers-registered.sh` | rc 0 chacun | ✓ PASS |
| critère 6 clients | `check-livraison-58.sh clients --base 2649ccd4` | rc 2 NON-VÉRIFIABLE | ? SKIP (jamais vert) |

Non rejoué, faute de consigne : le job `gates` complet et `check-prd` (13350 cas, 127 s) ; je m'en remets pour eux à `60-09-SUMMARY.md` après avoir vérifié ses composants. G-1 et G-2 non rejoués : `check-gate-touche.sh` juge une base `merge-base origin/main` (qui inclut des commits antérieurs à la phase, comme le dit 60-09) ; j'ai seulement vérifié les trailers à la lecture du journal.

## Probe Execution

Aucune sonde `probe-*.sh` déclarée par les plans de la phase ; non applicable.

## Requirements Coverage

| Exigence | Plan source | Statut | Évidence |
|----------|-------------|--------|----------|
| ARCG-01 | 60-01, 03, 04, 06 | PARTIAL (volet pose non prouvé) | voir vérité 1 |
| ARCG-02 | 60-01, 07 | SATISFIED | vérité 2 |
| ARCG-03 | 60-06 | SATISFIED au niveau contrat, comportement non prouvé | vérité 3 |
| ARCG-04 | 60-06 | idem | vérité 4 |
| ARCG-05 | 60-06 | idem | vérité 5 |
| ARCG-06 | 60-02, 04 | SATISFIED | vérité 6 |
| ARCG-07 | 60-02 | SATISFIED | vérité 7 |
| ARCG-08 | 60-05 | SATISFIED (structure) | vérité 8 |
| ARCG-09 | 60-05, 06 | NEEDS HUMAN | vérité 9 |
| ARCG-10 | 60-08 | SATISFIED | vérité 10 |
| ARCG-11 | 60-07, 09 | SATISFIED | vérité 11 |

Aucune exigence orpheline : les onze ID de `REQUIREMENTS.md` pour la Phase 60 sont portés par les plans.

## Anti-Patterns Found

| Fichier | Ligne | Motif | Gravité | Impact |
|---------|-------|-------|---------|--------|
| diff de la phase hors `.planning/` | - | `TBD`, `FIXME`, `XXX` | aucun | Les occurrences sont des données de test (`**Requirements**: TBD` dans des fixtures) ou le mot cité dans la règle de corps de `check-architecture.sh` : aucun marqueur de dette |
| `test-check-phase-validation.sh` | `probe_trace2` | commentaire de test dont l'assertion ne couvre pas ce qu'il annonce | WARNING | voir warning 1 |

## Human Verification Required

### 1. Run réel du flux d'équipe

**Test :** Sur un lab désigné au poste `dev` avec `.planning/BRIEF.md`, faire ajouter une phase par l'équipe (vérifier le marqueur `proposed`), dispatcher `vf-coder` sur cette phase (attendre `blocked` + `ask-user`), lancer `/vf-auto` sur elle (le moteur direct ne démarre pas), demander au head « ajoute une étape » sans architecture validée (halte avec motif), puis faire rédiger l'architecture par le worker.
**Expected :** Chaque refus se produit sans lancer `gsd-plan-phase` ni `gsd-execute-phase` ; `check-architecture.sh` rend code 1 `statut=proposee rubriques_manquantes=0` sur le livrable du worker ; `vf-validation.sh validate` les fait passer à code 0.
**Why human :** Comportement d'agents LLM, aucun test ne les fait agir. C'est le geste de P59-D-11 et la condition de `proposable:true`.

### 2. Liste de clients (ARCG-09)

**Test :** Poser la liste hors dépôt, rejouer `check-livraison-58.sh clients --base 2649ccd4`.
**Expected :** code 0.
**Why human :** liste absente du dépôt par construction.

### 3. Hypothèses du cadrage

**Test :** Confirmer P60-H-01 (gate seulement si `BRIEF.md` existe), H-02 (un dev valide l'architecture), H-03 (toute phase ajoutée par l'équipe aux postes product/dev naît proposée), H-04 (le gate lit le marqueur, jamais le poste), plus O-8 et P60-PL-06.
**Expected :** décision de Samuel, canal et date tracés.
**Why human :** hypothèses explicitement retenues faute de réponse humaine.

### 4. Seuil de preuve du ledger

**Test :** Trancher si ARCG-03, 04, 05 restent cochées sur texte ancré, ou repassent Partial comme ARCG-01.
**Expected :** un seuil uniforme.
**Why human :** jugement de gouvernance, pas une mesure.

## Gaps Summary

Aucun gap bloquant : aucune vérité FAILED, aucun artefact manquant ou stub, aucun lien non câblé, aucune valeur de baseline relevée, aucun skill ni hook ni fichier protégé touché, `check-prd.sh` intact. Le statut est `human_needed` parce que l'étape 8 produit des éléments qu'aucun script ne peut résoudre (comportement des agents, liste de clients, hypothèses de cadrage), pas parce que du travail a manqué. À corriger sans attendre, à faible coût : la lacune de test du warning 1 (un cas et un mutant à ajouter à `test-check-phase-validation.sh`, ce qui demande un trailer `Gate-Touche`). Le merge et la release restent des gestes du manager et de Samuel (arrêt avant PR conforme à ARCG-11).

---

_Verified: 2026-10-29_
_Verifier: Claude (gsd-verifier)_

## Reprise du 2026-10-29 (correction après fusion de main, v2.73.1)

Mandat ciblé du manager, après la ratification des hypothèses (arbitrage Samuel, AskUserQuestion session principale, 2026-10-29 :
« Oui aux propositions par défaut pour 60 et 61 », `60-CONTEXT.md` § Ratification). Branche fusionnée avec `origin/main`
(v2.73.1), entrées de la phase renumérotées en v2.74.0.

**Écart d'implémentation trouvé et aligné.** La conduite des consommateurs sur un résultat indéterminé n'était pas celle ratifiée :
`vf-coder` et `vf-auto` laissaient continuer sur tout code 3 ou 64 (sauf marqueur illisible). Cas où une phase marquée
« proposée » passait : lab partitionné sans `--ws` (le contrôle regarde ailleurs), sections multiples, ROADMAP absent ou
bloc de code non fermé qui avale la phase, identifiant mal formé (64). Aligné (P60-D-15) : seul « phase introuvable sans autre défaut »
(`BILAN marqueur=introuvable`) laisse continuer, tout autre indéterminé arrête. Preuve rouge : `git archive` de la tête d'avant la
correction dans une copie jetable, suites neuves posées dessus : `test-check-phase-validation.sh` 14 ko, `test-vf-validation.sh` 3 ko,
`test-dev-orchestrator.sh` 59 ko ; verts sur la correction (104 ok, 63 ok, 448 ok).

**Second cas, dans le gate.** Une ligne qui ressemble à un marqueur sans en avoir la forme exacte (`- **Validation:** proposed`,
`> …`, `Validation: proposed`, `**validation:** proposed`, `**Validation :** proposed`, case à cocher…) était lue « marqueur absent »,
donc phase validée (rc 0). Elle est désormais un marqueur illisible (rc 3, `marqueur=inconnu`), dans le gate ET dans l'écrivain
(qui n'insère plus une seconde ligne à côté). Témoins de non-sur-détection : `Validation: les tests passent`, `- Validation criteria: x`.
Sept mutants (CPV-MUT-47..53) et deux (VFV-MUT-25, 26) tués.

**Avertissement 1 de ce rapport (fermeture de section) : déjà fermé** par CPV-MUT-11 et 12 (commit `51eb2aae`), rejoués verts.

**Restent ouverts, non corrigeables par du code.**
- ARCG-01, volet « une phase ajoutée hors solo naît proposée » : BLOQUÉ sur un run réel de mission (head, manager, verbe), geste humain P59-D-11.
- ARCG-09, critère 6 `clients` : BLOQUÉ sur la liste de noms de clients, hors dépôt (code 2, jamais vert).
- Comportement des agents (ARCG-03, 04, 05) : texte ancré et commande exécutée, aucun run ; seuil de preuve du ledger à trancher par Samuel.
- P60-PL-06 et O-8 : conséquences de H-02 et H-03, non nommées dans la ratification.
