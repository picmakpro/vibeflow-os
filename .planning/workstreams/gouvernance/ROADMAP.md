# Roadmap: VibeFlow Dev Orchestrator (VFDO) — gouvernance-labs-v1.0

## Milestones

- 🚧 **gouvernance-labs-v1.0** — « le planning métier tenu par une machine » — Phases 42-50 —
  **inscrit 2026-09-23** — polarité gouvernance (Willy). Section de jalon distincte dans la ROADMAP
  plate, **sans `gsd-new-milestone`** : `STATE.md` reste mono-position et porte encore le jalon de
  Samuel (Phase 41 ouverte). Arbitrage Willy, AskUserQuestion session principale, 2026-09-23.
  Sources : les trois specs de `docs/superpowers/specs/` datées du 2026-09-22 (moteur de planning,
  fabrique d'agents et de skills) et du 2026-09-23 (initialisation d'un lab).

## Phases

- [ ] Phase 42: Fabrique — manifeste daté et invariants de doctrine du gate des agents (inscrite 2026-09-23, jalon gouvernance-labs-v1.0)
- [ ] Phase 43: Fabrique — gate des skills par nature et alignement de skill-creator (inscrite 2026-09-23, jalon gouvernance-labs-v1.0)
- [ ] Phase 44: Moteur — modèle de données et recalcul d'état dérivé du disque (inscrite 2026-09-23, jalon gouvernance-labs-v1.0)
- [ ] Phase 45: Moteur — hook central par rôle et gates d'écriture (inscrite 2026-09-23, jalon gouvernance-labs-v1.0)
- [ ] Phase 46: Moteur — gates de clôture et verdicts hachés (inscrite 2026-09-23, jalon gouvernance-labs-v1.0)
- [ ] Phase 47: Moteur — baux générationnels et jeton monotone (inscrite 2026-09-23, jalon gouvernance-labs-v1.0)
- [ ] Phase 48: Moteur — agents génériques de cycle, injection de l'index et pont mémoire (inscrite 2026-09-23, jalon gouvernance-labs-v1.0)
- [ ] Phase 49: Initialisation — script des trois gates de la grille (inscrite 2026-09-23, jalon gouvernance-labs-v1.0)
- [ ] Phase 50: Initialisation — grille, interview et fabrique des producteurs et juges (inscrite 2026-09-23, jalon gouvernance-labs-v1.0)

## 🚧 Milestone gouvernance-labs-v1.0 — « le planning métier tenu par une machine » (Phases 42-50)

> **Origine** : le planning des labs non-dev n'est pas tenu alors que celui du dev l'est presque
> sans faute — asymétrie mesurée et expliquée dans `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md`.
> Trois specs, un ordre dicté par leurs dépendances : **la fabrique** (son premier geste — les
> blueprints et I8 — est porté par la PR #85), puis **le moteur**, puis **l'initialisation**, qui
> produit ce que le moteur consomme et doit donc s'écrire contre un moteur existant. Premier geste
> de l'initialisation : le script des trois gates de la grille (C-14).
> Découpage, jalon distinct et ordre : arbitrage Willy, AskUserQuestion session principale,
> 2026-09-23. **Aucune exécution avant la clôture de `fiabilite-v1.0`** (Samuel, WhatsApp, 2026-09-23) :
> la planification avance, l'exécution attend. **Être inscrite ne vaut pas feu vert d'exécution** : chaque phase passe par
> `gsd-discuss-phase` puis `gsd-plan-phase`.
> **Amendement du 2026-09-24** : exécution en parallèle de `fiabilite` autorisée — autorisation Samuel du 2026-09-23 rapportée par Willy, session principale, 2026-09-24 (canal non précisé).
> **Garde-fous de cette exécution anticipée** (posés par la mission du 2026-09-24) : (1) **aucune release du jalon gouvernance avant la clôture de `fiabilite-v1.0`** — les numéros de version des modules partagés, `conductor` en tête, entreraient en collision avec ceux de `fiabilite` (la PR #100 porte `conductor` v1.40.0 → v1.41.0) ; une PR de ce jalon qui bumpe un module partagé se rebase et se renumérote après les merges de `fiabilite`, jamais l'inverse ; (2) **les gates de planning de ce compartiment se rejouent à la main** (`--file .planning/workstreams/gouvernance/STATE.md`) tant que la Phase 41.1 (PR #100 de Samuel) n'est pas mergée : la CI ne vérifie que `fiabilite`.

### Phase 42: Fabrique — manifeste daté et invariants de doctrine du gate des agents

**Goal:** Le gate des agents (`check-agents.sh`) lit ses listes de référence — outils, champs, types natifs, modèles, modes, niveaux d'effort — dans un **manifeste daté** et rend **INDÉTERMINÉ** quand ce manifeste est périmé ; il tient les invariants de doctrine I1 à I7 et découvre les agents récursivement.
**Requirements**: FABR-01, FABR-02, FABR-03, FABR-04, FABR-05
**Depends on:** Phase 41 et **clôture du jalon `fiabilite-v1.0`** — volet admin de la 41 posé par Willy, release, clôture, puis ouverture de celui-ci (Samuel, WhatsApp, 2026-09-23). **Levée le 2026-09-24** pour l'exécution, pas pour la release : autorisation Samuel du 2026-09-23 rapportée par Willy, session principale, 2026-09-24 (canal non précisé) ; voir les garde-fous de l'en-tête du jalon. **PR #85 mergée** : elle porte le premier geste de la fabrique (correctif des 9 blueprints + I8, `check-blueprints.sh`) — **mergée le 2026-09-23** (11:11 UTC, après ajout du trailer `Gate-Touche:` par Samuel) : précondition levée.
**Sources:** `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §1.1-1.3, §3, §4, B-01. Hors périmètre : §8 (`skills:`, `cacheTtl`, `maxTurns`, `color:`).
**Revue de Samuel (WhatsApp, 2026-09-23)** : décisions de corpus ratifiées ; trois ajouts au cadrage — D-18 (`vf-test-orchestrator` nomme `vf-dev-manager` et `vf-auto`), D-19 (effet d'`omitClaudeMd` sur `.claude/rules/*.md` mesuré, pas déduit), D-20 (faux vert de l'invocation nue de `check-agents.sh`, `.planning/codebase/CONCERNS.md:349`). **Plans à réviser avant exécution.**
**Plans:** 6 plans

Plans:
**Wave 1**

- [x] 42-01-PLAN.md — vague 1 (tracer) : manifeste daté lu par le gate, posé par l'installeur (`*.json`), refus sur manifeste illisible ; T54, T77-T82 (FABR-01) — Complete (2026-09-24)
- [x] 42-02-PLAN.md — vague 1 : corpus — mobile-test-team (I3), business-pilot-bundle et content-bundle (I5/I6), un commit et un bump patch par module (FABR-05) — Complete (2026-09-24)
- [x] 42-03-PLAN.md — vague 1 : corpus — growth-bundle et design-orchestrator (I5/I6), un commit et un bump patch par module (FABR-05) — Complete (2026-09-24)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 42-04-PLAN.md — vague 2 : fraîcheur — INDÉTERMINÉ sous `--manifest-freshness=strict` en CI, avertissement chez l'utilisateur, rétrogradation D-05 ; T83-T90, T103, MUT-F1/F2/D20 (FABR-02) — Complete (2026-09-25)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 42-05-PLAN.md — vague 3 : invariants locaux I1, I4, I5, I6, I7 en erreur, jumeaux négatifs et mutants ; corpus et blueprints verts (FABR-03, FABR-05) — Complete (2026-09-25)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 42-06-PLAN.md — vague 4 : découverte récursive (D-10), I2/I3 en monde fermé (D-09), conductor en mineure, relevé de relecture Samuel (FABR-03, FABR-04, FABR-05) — Complete (2026-09-25)

### Phase 43: Fabrique — gate des skills par nature et alignement de skill-creator

**Goal:** Chaque skill déclare sa nature (`vf-nature: referentiel | outil | procedure`, défaut « outil ») ; une procédure sans `ecrit:` ni rubrique de juge est refusée ; la dérive de forme procédurale non déclarée est détectée ; `skill-creator` demande la nature ; les deux déclarations MCP (`vf-mcp-consumer` / `vf-mcp-tools`) sont conservées comme réponses à deux besoins distincts (décision 1 d'ADR-051), la spec fabrique §1.2/§7.2 est amendée en ce sens et le mécanisme conservé est durci (grammaire de `vf-mcp-tools` validée, serveur nommé absent signalé, textes à une seule clé corrigés). Les trois marqueurs de détection de dérive (un gate bloquant, un livrable remis à un tiers, une couche de qualité) forment **un contrat unique** : l'initialisation les pose tels quels en questions factuelles (C-15), sans redéfinir la nature.
**Requirements**: FABR-06, FABR-07, FABR-08, FABR-09, FABR-10
**Exigences (2026-09-25)** : proposées par `43-CONTEXT.md` § Exigences proposées, gravées au ledger du compartiment à la planification.
**Amendement du goal (2026-09-25)** : la clause d'origine « les deux conventions MCP concurrentes n'en font plus qu'une » est remplacée par la décision D-Q3 de `43-CONTEXT.md` — Willy, AskUserQuestion, session principale, 2026-09-24 : « garder les deux déclarations ». La fusion est écartée ; la spec est amendée, le mécanisme durci.
**Depends on:** Phase 42 (le manifeste daté et la découverte récursive servent aussi ce gate).
**Sources:** `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §6, §7.2, B-03. **C'est le contrôle machine qui manque à la décision D-07** du moteur (`docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §2, §9). `docs/superpowers/specs/2026-09-23-initialisation-lab-design.md` C-15, §5.2 (la case « trois marqueurs de B-03 » remplace « qui en répond »).
**À embarquer (signalé par Samuel, WhatsApp, 2026-09-23)** : budget des `SKILL.md` et du bootstrap sans enforcement machine — `.planning/BACKLOG.md:450` ; la phase touche les skills, elle le prend au passage.
**Plans:** 7 plans

Plans:
**Wave 1**

- [ ] 43-01-PLAN.md — vague 1 (tracer) : `check-skills.sh` lit le manifeste daté élargi à sept listes, découvre le corpus réel à ses trois profondeurs, refuse une procédure sans `ecrit:`/`vf-rubrique-juge` ; valeurs validées strictement ; parité de contrat avec `check-agents.sh` (FABR-06, FABR-09 clause manifeste)
- [ ] 43-04-PLAN.md — vague 1 (tracer + checkpoint) : plafond de 500 lignes des SKILL.md dans `check-instruction-budget.sh` ; checkpoint humain sur le corpus et le mode du bootstrap (socle mesuré ≈ 2 500 tokens pour un plafond de 2 000) avant toute hausse de baseline (FABR-09)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 43-03-PLAN.md — vague 2 : `skill-creator` (moteur interne et workflow templaté) pose `vf-nature`, défaut « outil », distincte de la nature du sujet (FABR-08)
- [ ] 43-05-PLAN.md — vague 2 (tracer) : durcissements MCP — serveur nommé absent de l'union signalé jusqu'au journal d'installation, `vf-mcp-tools` malformée refusée à l'install et au gate, textes de l'installeur à deux déclarations, relecture Samuel (FABR-10)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 43-02-PLAN.md — vague 3 (après 43-03, révision du 2026-09-26) : dérive procédurale en écart déclaration/prose, dans les deux sens, en avertissement ; portée de détection suspendue à la réponse de Willy ; corpus réel mesuré, non corrigé (FABR-07)
- [ ] 43-07-PLAN.md — vague 3 : spec fabrique §1.2/§7.2 amendée (deux besoins distincts, fusion écartée, D-Q3), dev-orchestrator en patch — détaché de 43-05 à la révision du 2026-09-25 (FABR-10)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 43-06-PLAN.md — vague 4 : `vf-calibrate` à deux déclarations, conductor en mineure, rejeu complet (suites, corpus réel, G-1, G-2, labs frais), relevés de relecture et de résidus (FABR-06, FABR-07, FABR-09, FABR-10)

### Phase 44: Moteur — modèle de données et recalcul d'état dérivé du disque

**Goal:** Le modèle de données d'un lab (`cycles/`, `phases/`, `CADRAGE.md`, `PLAN.md` avec `ecrit:`, `VERDICT.md`, `SUMMARY.md`) existe, et un recalcul **en Python** dérive du disque les huit états (dont `indéterminé`) et génère `INDEX.md`, `STATE.md` et `cloture.log` — incrémental par hash du contenu, jamais par `mtime`.
**Requirements**: TBD (posés au cadrage)
**Depends on:** Phase 43 (seule une procédure ouvre une phase : la nature doit être déclarée avant que le moteur ne s'en serve).
**Sources:** `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §3, §7.1, §7.4, §10, D-03, D-09, D-10. **Ouvert au cadrage** : emplacements hors modèle (§7.3), arbitrage d'usage `phases_trace: false` (§11.2), premier banc d'essai.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 44 to break down)

### Phase 45: Moteur — hook central par rôle et gates d'écriture

**Goal:** Un hook central lit `agent_type` et refuse par rôle (juge, worker, producteur) ; les gates d'écriture G1, G5, G6 et G7 refusent par `permissionDecision: deny`, G2 avertit ; chaque gate déclare son comportement fail-closed, se prouve en vie par un canary, mesure ses faux refus dans les deux sens, et la dérogation est nominative et journalisée.
**Requirements**: TBD (posés au cadrage)
**Depends on:** Phase 44 (les gates lisent le modèle et les états dérivés).
**Sources:** `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §5, §5.1, §5.2, D-05 (G7) ; `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §5, B-02 — **une mécanique, deux chantiers**.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 45 to break down)

### Phase 46: Moteur — gates de clôture et verdicts hachés

**Goal:** La clôture d'une tâche est refusée quand un livrable déclaré manque (G3) ou qu'un constat du verdict échoue (G4) ; un rapport de sous-agent sans sortie brute est refusé (G4′) ; `VERDICT.md` porte le hash de l'artefact jugé et un numéro de tentative ; `FileChanged` trace toute écriture surveillée (D1) ; au premier cycle, le canary joue la **sortie piégée** que l'initialisation a préparée pour chaque juge, et signale le juge qui ne la refuse pas (C-16).
**Requirements**: TBD (posés au cadrage)
**Depends on:** Phase 45.
**Sources:** `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §5 (G3, G4, G4′, D1), §10, D-02 (le juge ne bloque que sur ses constats) ; `docs/superpowers/specs/2026-09-23-initialisation-lab-design.md` C-16, §10 (préparer la preuve sans l'exécuter, B-01).
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 46 to break down)

### Phase 47: Moteur — baux générationnels et jeton monotone

**Goal:** Un bail générationnel porte les fichiers d'état réécrits en place, au fichier près ; son numéro de génération est un jeton monotone vérifié par le hook **et** par l'écrivain, qui rejette l'écriture périmée d'une session revenue, d'un cron ou d'un sous-agent en fan-out ; à la clôture, G2′ refuse ce qui a bougé hors du bail sans amendement.
**Requirements**: TBD (posés au cadrage)
**Depends on:** Phase 46 (G2′ se branche sur le même événement `TaskCompleted` que G3/G4 ; il vit ici parce qu'il consomme le bail).
**Sources:** `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §6 (6.1 à 6.4), §5 (G2′), D-04.
**À embarquer (signalé par Samuel, WhatsApp, 2026-09-23)** : `save()` de `dag.sh` sans verrou ni écriture atomique, lost update silencieux — `.planning/BACKLOG.md:74`. C'est la même classe d'écriture concurrente que les baux : le jeton monotone doit la couvrir, ou la phase dit pourquoi non.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 47 to break down)

### Phase 48: Moteur — agents génériques de cycle, injection de l'index et pont mémoire

**Goal:** Les agents génériques de cycle — cadreur, planificateur, contrôleur de plan, orchestrateur de phase, plus chercheur et cartographe — sont livrés par le plugin **dans le module du moteur métier, pas dans le `team-kernel` partagé** (contrainte 1 ci-dessous ; libellé aligné le 2026-09-23, il disait l'inverse) ; l'index est injecté sur toutes les sources de session ; les lignes `ARBITRÉ` structurantes sont promues en mémoire à la clôture ; les cycles récurrents ont une cadence.
**Requirements**: TBD (posés au cadrage)
**Depends on:** Phase 47.
**Sources:** `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §4, §7.1-7.3, §7.5, §8, §9.2 (exemption de re-cadrage des procédures). **Ouvert** : registre cible d'une clôture (§7.5), blocage par un tiers (§8).

**Contraintes (arbitrage Samuel, 2026-09-23)** : risque mesuré au moment de l'inscription —
`plugin/conductor/references/team-kernel.md` est lu par les managers dev ET design ET les bundles
business/content ; les rôles génériques visés (cadreur, planificateur, contrôleur de plan,
orchestrateur) dédoublent `gsd-discuss-phase`, `gsd-plan-phase`, le plan-checker et `vf-coder` ; un
lab dev reçoit déjà son état par les hooks GSD au démarrage de session. Relayé à Willy par
WhatsApp le 2026-09-23.

1. **Aucun ajout dans le `team-kernel` partagé si c'est évitable.** Les agents génériques de cycle
   vivent dans le module du moteur métier. Si une modification du noyau s'avère nécessaire, elle
   est **additive**, explicitement **portée non-dev**, et sa nécessité est démontrée (pourquoi le
   module seul ne suffit pas).
2. **Zéro régression sur les labs dev — exigence non négociable, prouvée par une mesure, pas
   déclarée.** Ce dépôt est un lab dev ; comportement identique avant/après sur le routage du head,
   les hooks de démarrage de session et la doctrine des managers dev. La preuve doit pouvoir
   rendre rouge (mutation exécutée), sinon elle ne compte pas.
3. **Injection d'index réservée aux labs pilotés par le moteur métier.** Un lab dev garde ses
   messages GSD : jamais deux moteurs qui injectent un état, donc jamais deux vérités sur la phase
   courante.
4. **Contrainte de profondeur (v2.63.2, mesurée le 2026-09-17)** : tout agent générique qui en
   dispatche un autre vérifie la chaîne complète — l'outil Agent est absent à la profondeur 3.

**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 48 to break down)

### Phase 49: Initialisation — script des trois gates de la grille

**Goal:** Un script exécute les trois gates de la grille — aucune case sans disposition, aucune case sans usage, aucun élément sans case — ignore les marqueurs dans les blocs de code, traite le fichier absent comme un refus et lit les dispositions quel que soit le format de ligne (item `-`, `*` ou numéroté, citation `>`, gras, espace avant les deux-points, sans accent) ; la famille 0 (l'interlocuteur) est exemptée du gate 2 **par déclaration explicite dans le schéma de la grille**, jamais par jugement du script ; ses tests prouvent qu'il refuse.
**Requirements**: TBD (posés au cadrage)
**Depends on:** Phase 48 — **le moteur précède l'initialisation**, qui produit ce qu'il consomme (arbitrage Willy, AskUserQuestion session principale, 2026-09-23). Premier geste de l'initialisation.
**Sources:** `docs/superpowers/specs/2026-09-23-initialisation-lab-design.md` §3, §5.4, §11, §15, C-01, C-14 (version corrigée après passe adversariale, `ca4dada`).
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 49 to break down)

### Phase 50: Initialisation — grille, interview et fabrique des producteurs et juges

**Goal:** `/vf-new-lab` calibre l'interlocuteur, inventorie l'existant, remplit la grille à dix familles par récit puis questions avec un critère d'arrêt déterministe, échange des faits sourcés, cartographie le contexte, et ne fabrique que des producteurs et des juges. Le **mode express** passe à quatre cases (objectif mesurable, livrables, critère de réussite, critère d'échec) **plus le plancher complet** — récit d'ancrage, pré-mortem, validation du récapitulatif — (arbitrage Willy, AskUserQuestion, 2026-09-23) ; les contrôles humains proposés ne se valident jamais d'un geste (C-13) ; la nature de chaque livrable se déclare par les trois marqueurs de B-03 (C-15) ; chaque juge reçoit une sortie piégée tirée de l'exemple raté, préparée mais non exécutée (C-16).
**Requirements**: TBD (posés au cadrage)
**Depends on:** Phase 49.
**Sources:** `docs/superpowers/specs/2026-09-23-initialisation-lab-design.md` §3-§12, §15, C-01 à C-16. Hors périmètre : couche interrogeable de FileFlow, veille, restructuration de BusinessFlow-Lab (§13).
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 50 to break down)
