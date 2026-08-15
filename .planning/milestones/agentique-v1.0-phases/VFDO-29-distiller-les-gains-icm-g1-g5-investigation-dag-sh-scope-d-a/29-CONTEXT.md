# Phase 29: Distiller les gains ICM (G1-G5) — investigation dag.sh --scope d'abord - Context

**Gathered:** 2026-08-15
**Status:** Ready for planning

> Cadrage court par choix explicite de Samuel : le pré-cadrage (AskUserQuestion du 2026-08-15) a
> tranché les trois arbitrages de périmètre, puis les zones grises d'implémentation ont TOUTES été
> déléguées (« Rien » au menu de discussion) — elles sont en Claude's Discretion, à instruire par
> la recherche et le plan. Le contexte de fond vit dans le rapport de deep-search (canonical ref
> n°1), pas dans ce fichier.

<domain>
## Phase Boundary

Distiller dans l'outillage et la doctrine VibeFlow les mécanismes retenus de la deep-search ICM :
G3 (gate anti-drift carte↔disque), G1 (anti-chargement déclaré — tables « Load / DO NOT Load » +
le négatif du périmètre `--scope` dans les digests de mission), G5 (Edit-Source Principle dans la
doctrine des managers), G2 (CONTEXT.md ≤ 80 lignes par compartiment + `_index.md` des dossiers de
références > 10 fichiers). **Précondition transverse : investigation de l'historique et des
consommateurs de `dag.sh --scope` AVANT tout geste G1 — zéro régression autorisée sur le
mécanisme de scope** (il porte le dispatch parallèle des périmètres disjoints du team-kernel,
Phase 27 / PAEX). Jamais d'adoption du label ICM, du modèle mono-agent, ni de restructuration de
`.planning/` (GSD propriétaire, ADR-055).

</domain>

<decisions>
## Implementation Decisions

### Périmètre (pré-cadrage 2026-08-15, AskUserQuestion)
- **D-01:** G4 (lab-starters clonables à placeholders pour `vf-new-lab`) est **DÉCOUPÉ hors de la
  Phase 29** — phase dédiée à inscrire plus tard, à instruire conjointement avec les items backlog
  « agency-agents » et « Template d'agent installable » qu'il recoupe. La 29 livre G1/G2/G3/G5 +
  l'investigation `--scope`.
- **D-02:** Les gains secondaires du rapport (budgets tokens par couche, colonne `Section/Scope`
  dans les mandats, frame « compilateur », pipelines ICM purs pour labs non-dev) sont **HORS
  périmètre** — ils restent au backlog, aucun ne s'invite dans les livrables de la 29.
- **D-03:** **Zéro régression autorisée sur `dag.sh --scope`** : l'investigation (historique
  Phase 27/D-13, consommateurs — `partitionStages()`, frontière `ready --stage`, doctrine
  team-kernel.md:19 et mission-flow.md:106/244-247 —, suite `test-dag.sh`) précède et conditionne
  tout geste G1. Si un geste G1 exige de toucher `dag.sh`, la voie « doctrine seule / manager
  rédige » est la position de repli qui garantit la non-régression par construction.
  — **Reversibility:** one-way — une régression du scope casserait le dispatch parallèle des
  managers en production chez les utilisateurs du plugin ; c'est la raison d'être de la
  précondition, pas un simple ordre des tâches.

### Claude's Discretion (déléguées explicitement — « Rien » au menu de discussion)
- **G3** : choix des paires carte↔disque du v1 (folder maps des CLAUDE.md, `skills:` des
  frontmatters, compteurs STATE/ROADMAP…), emplacement du script (conductor hook vs phase
  validator), mode lint-only vs lint+update — en respectant ADR-031 (jamais de fix sans
  validation humaine) et le précédent `check-doc-drift.sh` (constater le FAIT, jamais juger le
  métier).
- **G1** : forme de l'anti-chargement (digest, templates d'agents, CLAUDE.md scaffoldés) et
  mécanisme du négatif du scope (calculé vs rédigé) — sous la contrainte D-03.
- **G2** : `scaffold-docs.sh` à la création seulement vs rattrapage `vf-calibrate` ;
  `_index.md` machine-généré vs rédigé.
- **G5** : emplacement de la règle Edit-Source (team-kernel.md vs mission-flow.md vs les deux
  + pattern méthodo) — en tenant compte de la charte de densité ADR-029.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Le cadrage amont de cette phase (à lire en premier)
- `reports/research/2026-08-15-icm-deep-search.md` — le rapport de deep-search qui définit
  G1/G2/G3/G5 (§5, avec levier/coût), ce qu'on ne prend pas (§6), et les suites proposées (§7).
  C'est la source du périmètre ; les gains y sont spécifiés plus finement que dans le ROADMAP.

### Le mécanisme à ne pas régresser (G1 / investigation --scope)
- `plugin/conductor/scripts/dag.sh` — `scope[]` : construction du nœud (l.222-224), lecture
  tolérante `node.get("scope", [])` (l.291-300), `partitionStages()` ; « ne réimplémente AUCUNE
  comparaison de scope[] localement » (l.167).
- `plugin/conductor/scripts/tests/test-dag.sh` — la suite existante (33K) : le contrat de
  non-régression de départ.
- `plugin/conductor/references/team-kernel.md` §table l.19 — la frontière `ready` comme liste à
  dispatcher en parallèle quand les périmètres sont disjoints.
- `plugin/dev-orchestrator/references/mission-flow.md` l.106, l.244-247 — la pose du nœud avec
  `--scope`, et le périmètre déclaré comme ce qui rend le critère calculable.
- `.planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-CONTEXT.md`
  — le cadrage qui a produit le trou fermé de `dag.sh` et la décision D-13 (scope déclaré à la
  pose) ; l'historique que l'investigation doit reconstituer.

### Les surfaces à modifier (G1/G2/G3/G5)
- `plugin/dev-orchestrator/references/mission-contracts.md` §49-77 — le format du digest ≤ 30
  lignes (G1 y ajoute son négatif) et la règle « le disque gagne ».
- `plugin/conductor/scripts/scaffold-docs.sh` — le poseur de squelette doc des labs (G2).
- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` — le précédent de gate drift « fait,
  jamais métier » dont G3 est l'extension structurelle.
- `plugin/reference/content/methodology/patterns/` — les 12 patterns ; G5 peut en toucher la
  doctrine, ADR-029 contraint la densité partout.

### Gouvernance
- `docs/ADR.md` — ADR-029 (densité), ADR-031 (jamais de fix sans validation humaine — borne le
  mode « update » de G3), ADR-044 (check-agents), ADR-055 (GSD propriétaire de `.planning/`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `check-doc-drift.sh` : modèle de gate drift factuel (SIG-03) — G3 en est le grand frère
  structurel (incohérence, pas immobilité).
- `test-dag.sh` (33K) : harnais de test existant de `dag.sh` — l'investigation `--scope` s'y
  adosse au lieu de créer un harnais neuf.
- `check-agents.sh` : précédent de lint machine-enforced avec modes `--hook`/`--strict`/codes de
  sortie typés (0/1/3) — la grammaire de sortie que G3 devrait parler.
- `scaffold-docs.sh` (89 L, idempotent) : le point d'entrée naturel de G2.

### Established Patterns
- Axiome 1 « Enforcement > prose » (AXIOMES-ENFORCEMENT.md) : G3 et G1 doivent finir
  machine-vérifiables, pas en consigne.
- Doctrine des gates : sortir « NON VERIFIABLE » plutôt qu'un faux vert (précédent exit 3
  INDÉTERMINÉ de check-agents, leçon « vacuous green » de la mémoire du validator).
- Densité ADR-029 : toute addition doctrinale (G1/G5) se paie en lignes — déporter en
  references on-demand si besoin.

### Integration Points
- Hooks SessionStart du conductor (`hooks.json`) si G3 devient un signal de session.
- La phase 2 de `vibeflow-validator` (densité) si G3 s'ancre côté audit.
- `vibeflow-update.sh` ne bouge pas : aucun nouveau type d'install requis a priori.

</code_context>

<specifics>
## Specific Ideas

- Samuel : « je veux aussi investiguer l'histoire du DAG --scope car pas de régression
  autorisée » — l'investigation est un livrable à part entière, pas un préambule jetable.
- Le rapport ICM propose la forme cible de G1 : table `| Tâche | Charge | NE charge PAS |`
  (pattern « Do NOT Load » de RinDig) — point de départ, pas contrainte.

</specifics>

<deferred>
## Deferred Ideas

- **G4 — lab-starters clonables à placeholders** (phase dédiée à inscrire) : à instruire avec les
  items backlog « agency-agents » et « Template d'agent installable » — trois entrées, un seul
  chantier probable.
- **Gains secondaires ICM** (budgets tokens par couche, `Section/Scope` dans les mandats, frame
  « compilateur », pipelines ICM purs pour labs non-dev simples) — au backlog, réévaluables après
  la 29.

</deferred>
