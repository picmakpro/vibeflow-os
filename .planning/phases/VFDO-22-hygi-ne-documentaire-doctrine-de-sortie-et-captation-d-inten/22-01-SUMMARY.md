---
phase: 22-hygiene-documentaire
plan: 01
subsystem: doctrine
tags: [dev-orchestrator, gsd-docs-update, intent-routing, adr-029, adr-031, adr-055, adr-057]

requires:
  - phase: 13-pont-spec-feuille-de-route
    provides: "ingestion-flow.md — la doctrine d'entrée dont docs-flow.md est le symétrique, et son gabarit structurel"
  - phase: 17-signaux-de-demarrage
    provides: "check-doc-drift.sh et le signal [doc-drift] — le FAIT que la nouvelle doctrine gradue sans le modifier"
provides:
  - "docs-flow.md — la doctrine documentaire de sortie, 4 familles distinguées (produit / code / savoir / entrée par renvoi)"
  - "Le régime gradué : --verify-only libre (read-only), génération sous confirmation, --force annoncé et jamais en mission"
  - "La captation d'intention qui distingue auditer de générer de régénérer, en langage naturel"
  - "Le protocole de désambiguïsation des 4 familles (D-10), 4 ancrages contextuels + question courte sur formulation creuse"
  - "Le bloc T22 étendu — la doctrine ET son routage sont gardés par la machine"
affects: [22-02 (les managers consomment la table de déclencheurs de docs-flow.md), 22-03 (bump du module dev-orchestrator), 23 (recoupement sur la doctrine des flags documentaires)]

actuals:
  tokens: 21000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Doctrine on-demand symétrique : un fichier de référence par famille de geste, chargé seulement quand l'intention apparaît (coût contexte nul sinon)"
    - "Assertion par chaînage de greps : une seule ligne physique doit porter N notions, vérifiée en pipe et non par N greps indépendants"

key-files:
  created:
    - plugin/dev-orchestrator/references/docs-flow.md
  modified:
    - plugin/dev-orchestrator/references/intent-routing.md
    - plugin/dev-orchestrator/AGENT.md
    - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh

key-decisions:
  - "docs-flow.md hébergé dans dev-orchestrator (D-01), pas dans le team-kernel — le conductor hébergerait une doctrine parlant d'outils gsd-* absents de son propre module"
  - "Les 4 familles traitées en propre sauf l'entrée, qui est un RENVOI vers ingestion-flow.md et jamais une copie (D-02, ADR-057)"
  - "Gradation par le risque réel : --verify-only n'écrit rien donc il est libre ; la génération commite donc elle est gatée (D-03)"
  - "--force autorisé sur intention explicite (D-05, arbitrage de Samuel CONTRE la recommandation) mais borné par l'annonce de ce qui sera écrasé (D-06)"
  - "check-doc-drift.sh laissé strictement inchangé (D-13) — le script constate le FAIT, la doctrine porte le JUGEMENT (ADR-055 §3)"

patterns-established:
  - "Trois régimes d'une même brique ≠ trois briques : --verify-only / défaut / --force sont routés séparément dans intent-routing.md car ils répondent à trois intentions distinctes, sans jamais toucher §Couverture ni la whitelist du test d'exhaustivité"
  - "Chaînage de greps pour les lignes rouges : trois greps indépendants sont satisfaits par trois mentions dispersées, c'est-à-dire par rien"

requirements-completed: [DOCF-01, DOCF-02, DOCF-03, DOCF-04]

coverage:
  - id: D1
    description: "docs-flow.md existe, symétrique d'ingestion-flow.md, et traite les 4 familles documentaires"
    requirement: "DOCF-01"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T22 docs-flow"
        status: pass
    human_judgment: false
  - id: D2
    description: "Le régime gradué de confirmation est écrit : --verify-only libre, génération gatée, autonome = constat"
    requirement: "DOCF-02"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T22 (--verify-only, ADR-031)"
        status: pass
    human_judgment: false
  - id: D3
    description: "La ligne rouge --force tient sur une seule ligne physique portant le flag, la mission et l'autonome"
    requirement: "DOCF-03"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T22 ligne rouge --force (chaînage de 3 greps)"
        status: pass
    human_judgment: true
    rationale: "La machine prouve que le texte est là et qu'il porte les trois notions sur une ligne ; elle ne peut pas prouver qu'il dit ce que Samuel a décidé en D-05/D-06. Le checkpoint humain du plan 22-02 porte précisément sur cette formulation."
  - id: D4
    description: "« vérifie que la doc dit encore vrai » et « refais toute la doc » tombent sur deux gestes distincts et nommés"
    requirement: "DOCF-04"
    verification:
      - kind: unit
        ref: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh#T22 captation (--verify-only, --force, formulations, désambiguïsation, plancher 8 lignes)"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-07-31
status: complete
---

# Phase 22 — Plan 01 Summary

**Le moteur de dev sait désormais que « la doc » désigne quatre choses différentes, et distingue auditer de générer de régénérer — trois intentions que la carte d'intention confondait en une seule ligne.**

## Performance

- **Duration:** ~45 min (dont une interruption par épuisement de quota, reprise inline)
- **Tasks:** 3 / 3
- **Files modified:** 4 (1 créé, 3 modifiés)

## Accomplishments

- **`docs-flow.md` (111 lignes)** — la doctrine de sortie qui manquait, strictement symétrique
  d'`ingestion-flow.md` : table de discernement des 4 familles, une section par famille traitée en
  propre, renvoi (jamais copie) vers `ingestion-flow.md` pour l'entrée, table des 4 déclencheurs
  factuels, garde-fous, et `## Interdits` en clôture.
- **Le flag `--verify-only` est exposé pour la première fois.** Il répondait déjà à une intention
  parfaitement distincte — savoir si la doc dit encore vrai, sans rien écrire — et n'était routé
  nulle part. C'est le geste par défaut sur signal `[doc-drift]`.
- **La ligne unique de captation est éclatée en trois régimes** plus les deux familles code et
  savoir enrichies, avec un protocole de désambiguïsation à 4 ancrages contextuels.
- **La garde machine porte sur le routage, pas seulement sur la doctrine** — sans quoi la doctrine
  aurait pu exister tout en restant inatteignable en langage naturel, ce qui aurait manqué la
  moitié du but de la phase.

## Task Commits

1. **Tâche 1 (tracer) : la doctrine prouvée de bout en bout** — `19c6d72` (feat)
2. **Tâche 2 : les 4 familles, la ligne rouge `--force`, la frontière `vibeflow-os`** — emportée
   dans `431e12d` (wip) — *voir Issues Encountered*
3. **Tâche 3 : la captation d'intention et la désambiguïsation** — `a98b516` (feat)

## Files Created/Modified

- `plugin/dev-orchestrator/references/docs-flow.md` *(créé, 111 l.)* — la doctrine documentaire de sortie
- `plugin/dev-orchestrator/references/intent-routing.md` — §Contexte & session : 3 régimes + 2 familles + protocole de désambiguïsation (9 lignes de table, plancher 8)
- `plugin/dev-orchestrator/AGENT.md` *(181 → 188 l., plafond ADR-029 250)* — puce d'hygiène graduée vers l'audit d'abord, ligne `[doc-drift]` couplée à la doctrine, 2 lignes de carte d'intention
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — bloc T22 étendu (jamais un bloc nouveau : le compteur de suites du dépôt reste à 44)

## Decisions Made

- **La table des déclencheurs n'existe qu'à un seul endroit.** `AGENT.md` la cite par renvoi plutôt
  que de la dupliquer : l'agent conversationnel n'est pas un manager de mission, et la densité
  ADR-029 sanctionne la duplication. C'est le patron déjà en place pour `mission-flow.md` §Pattern E.
- **Les flags sont des variantes d'appel, pas des briques.** Ils sont donc routés dans les tables
  d'intention sans toucher §Couverture : `T14` compte des noms `gsd-*` et reste vert par
  construction, aucune whitelist nouvelle.

## Deviations from Plan

Aucune déviation de contenu — le plan a été exécuté comme écrit.

## Issues Encountered

**L'exécuteur a été interrompu en plein vol par l'épuisement du quota hebdomadaire d'API**, entre la
tâche 2 (faite, non commitée) et la tâche 3 (non commencée). Reprise **inline** plutôt que par
re-dispatch d'un sous-agent, après un état des lieux sur pièce : 1 commit atteint, `docs-flow.md`
intégralement écrit, `test-dev-orchestrator.sh` modifié mais non commité, aucun SUMMARY. Rien n'a
été re-exécuté à l'aveugle.

**Conséquence sur l'historique, à signaler :** une session tierce travaillant en parallèle sur ce
dépôt (Phases 23 et 24) a commité un `wip(22)` de sauvegarde qui a **emporté le fichier de test de
la tâche 2** avec ses propres modifications de `ROADMAP.md` et `STATE.md`. Le contenu est correct et
la suite est verte, mais la tâche 2 n'a pas de commit atomique propre : elle vit dans `431e12d`,
mêlée à du travail qui n'appartient pas à cette phase. L'historique n'a pas été réécrit — corriger
un commit d'une autre session aurait été plus dommageable que de documenter le fait ici.

## User Setup Required

Aucune — aucun service externe.

## Next Phase Readiness

**Prêt pour le plan 22-02.** `docs-flow.md` §Déclencheurs est la table que les deux managers vont
citer par renvoi ; sa forme est figée et gardée par T22.

**Point d'attention pour 22-02 :** son checkpoint humain porte sur la formulation de `--force`
(D-05/D-06). La machine prouve que les trois notions sont sur une ligne ; elle ne peut pas prouver
que le texte dit ce que Samuel a décidé. C'est la seule chose de cette phase qui demande son œil.

---
*Phase: 22-hygiene-documentaire, plan 01*
*Completed: 2026-07-31*
