# Roadmap: VibeFlow Dev Orchestrator (VFDO) — gouvernance-labs-v1.0

## Milestones

- 🚧 **gouvernance-labs-v1.0** — « le planning métier tenu par une machine » — Phases 42-50 —
  **inscrit 2026-09-23** — polarité gouvernance (Willy). Section de jalon distincte dans la ROADMAP
  plate, **sans `gsd-new-milestone`** : `STATE.md` reste mono-position et porte encore le jalon de
  Samuel (Phase 41 ouverte). Arbitrage Willy, AskUserQuestion session principale, 2026-09-23.
  Sources : les trois specs de `docs/superpowers/specs/` datées du 2026-09-22 (moteur de planning,
  fabrique d'agents et de skills) et du 2026-09-23 (initialisation d'un lab).

## Phases

- [x] Phase 42: Fabrique — manifeste daté et invariants de doctrine du gate des agents (inscrite 2026-09-23, jalon gouvernance-labs-v1.0) — clôturée 2026-09-27, PR #108
- [x] Phase 43: Fabrique — gate des skills par nature et alignement de skill-creator (inscrite 2026-09-23, jalon gouvernance-labs-v1.0) — clôturée 2026-09-27, PR #111
- [x] Phase 44: Moteur — modèle de données et recalcul d'état dérivé du disque (inscrite 2026-09-23, jalon gouvernance-labs-v1.0) — clôturée 2026-09-28, PR vers main ouverte (non mergée)
- [x] Phase 45: Moteur — hook central par rôle et gates d'écriture (inscrite 2026-09-23, jalon gouvernance-labs-v1.0) — cadrée et planifiée 2026-09-29 (10 plans, 8 vagues) ; exécutée 2026-09-30 → 2026-10-02 (10/10 plans, 15 quick de correction), cinq gates ARMÉS en cascade le 2026-10-01 ; audit de sécurité final SECURED (4 tours) ; vérifiée 15/15 — clôturée 2026-10-02 (clôture validée par Willy, message en session principale, 2026-10-01), PR #124 ouverte (non mergée)
- [ ] Phase 46: Moteur — gates de clôture et verdicts hachés (inscrite 2026-09-23, jalon gouvernance-labs-v1.0) — cadrée et planifiée 2026-10-03 (12 plans, 9 vagues, plan-check frais PASSED), PR de planification empilée sur la PR #124
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
**Plans:** 6/6 plans executed
**Clôture :** PR #108 mergée le 2026-09-27 (contournement de la revue code owner D-02bis, arbitrage Willy, session principale, 2026-09-27 ; revue de Samuel à faire après coup).

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
**Plans:** 7/7 plans executed
**Clôture :** PR #111 mergée le 2026-09-27 (commit 556452e), après deux merges amont dans sa branche (a2517df et le merge de la PR #112, intégration par merge plutôt que rebase pour ne pas réécrire les SHA cités — arbitrage Willy, session principale, 2026-09-27). Contournement de la revue code owner D-02bis, arbitrage Willy, session principale, 2026-09-27 ; revue de Samuel à faire après coup.

Plans:
**Wave 1**

- [x] 43-01-PLAN.md — vague 1 (tracer) : `check-skills.sh` lit le manifeste daté élargi à sept listes, découvre le corpus réel à ses trois profondeurs, refuse une procédure sans `ecrit:`/`vf-rubrique-juge` ; valeurs validées strictement ; parité de contrat avec `check-agents.sh` (FABR-06, FABR-09 clause manifeste)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 43-04-PLAN.md — vague 2 (après 43-01, seul propriétaire de la base de phase figée — révision du 2026-09-26) : plafond de 500 lignes des SKILL.md dans `check-instruction-budget.sh` ; bootstrap en ratchet sur le socle minimal (ligne de baseline `@bootstrap:socle` à la mesure du jour, ≈ 2 499 tokens pour un plafond ADR-029 de 2 000 qui reste un objectif, BACKLOG) — décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26 (FABR-09)
- [x] 43-03-PLAN.md — vague 2 : `skill-creator` (moteur interne et workflow templaté) pose `vf-nature`, défaut « outil », distincte de la nature du sujet (FABR-08)
- [x] 43-05-PLAN.md — vague 2 (tracer) : durcissements MCP — serveur nommé absent de l'union signalé jusqu'au journal d'installation, `vf-mcp-tools` malformée refusée à l'install et au gate, textes de l'installeur à deux déclarations, relecture Samuel (FABR-10)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 43-02-PLAN.md — vague 3 (après 43-03, révision du 2026-09-26) : dérive procédurale en écart déclaration/prose, dans les deux sens, en avertissement ; portée : tout le corps hors blocs de code, alerte à partir de deux marqueurs distincts en prose ou d'un seul dans un titre (décision déléguée par Willy au head (/vf-decide), AskUserQuestion session principale, 2026-09-26) ; corpus réel mesuré (10/21 au 2026-09-26), non corrigé (FABR-07)
- [x] 43-07-PLAN.md — vague 3 : spec fabrique §1.2/§7.2 amendée (deux besoins distincts, fusion écartée, D-Q3), dev-orchestrator en patch — détaché de 43-05 à la révision du 2026-09-25 (FABR-10)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 43-06-PLAN.md — vague 4 : `vf-calibrate` à deux déclarations, conductor en mineure, rejeu complet (suites, corpus réel, G-1, G-2, labs frais), relevés de relecture et de résidus (FABR-06, FABR-07, FABR-09, FABR-10)

### Phase 44: Moteur — modèle de données et recalcul d'état dérivé du disque

**Goal:** Le modèle de données d'un lab (`cycles/`, `phases/`, `CADRAGE.md`, `PLAN.md` avec `ecrit:`, `VERDICT.md`, `SUMMARY.md`) existe, et un recalcul **en Python** dérive du disque les huit états (dont `indéterminé`) et génère `INDEX.md`, `STATE.md` et `cloture.log` — incrémental par hash du contenu, jamais par `mtime`.
**Requirements**: MOTR-01..MOTR-18 (posées au cadrage, `44-CONTEXT.md`)
**Depends on:** Phase 43 (seule une procédure ouvre une phase : la nature doit être déclarée avant que le moteur ne s'en serve).
**Sources:** `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §3, §7.1, §7.4, §10, D-03, D-09, D-10. **Ouvert au cadrage** : emplacements hors modèle (§7.3), arbitrage d'usage `phases_trace: false` (§11.2), premier banc d'essai.
**Plans:** 5 plans (4 vagues : 44-01 ∥ 44-02 → 44-03 → 44-04 → 44-05)

Plans:
**Wave 1**

- [x] 44-01-PLAN.md — traceur : `recalc-planning.sh` (Python embarqué, voie a de P44-D-14) dérive le lab `traceur`, refuse sans adhésion `cycles-v1` ou sur GSD, lecture seule sans écriture, INDEX.md/STATE.md/cloture.log déterministes, lab frais
- [x] 44-02-PLAN.md — modèle : `references/modele-cycles.md` et huit gabarits `templates/cycles/` (choix délégués fixés)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 44-03-PLAN.md — matrice des huit états et des dérogations, jumeaux négatifs au banc, agrégation des plans et des cycles, gabarits conformes

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 44-04-PLAN.md — hors modèle (P44-D-04) et garde-fous de chemin ; incrémental par hash du contenu (P44-D-13) ; contrôle croisé référence ↔ moteur

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 44-05-PLAN.md — bump mineur de planning-core sans release, preuves de phase (P44-D-01a, P44-D-01b, P44-D-15), passage en lecture seule sur deux labs réels

**Clôture :** 2026-09-28, mission `mgr-44-reprise`. Après la vérification (PASSED 18/18), huit lots
de correction issus de la revue et de l'audit (quick tasks 260928-b4c, -ccz, -mgu, -ol3, -q6h, -s53,
-vk9) : le moteur appelle le vrai détecteur dans un environnement construit de zéro et n'écrit que
s'il a pu lire tout ce que le détecteur devait lire ; le journal `cloture.log` est encodé de façon
injective. Audit final SECURED (constats A et B du tour 1 fermés). Lot 8 sans nouveau tour de juges
et résidus acceptés (TOCTOU local, volume) : décision du head sous délégation technique de Willy,
session principale, 2026-09-28 — documentés dans `plugin/planning-core/references/modele-cycles.md`
et `.planning/BACKLOG.md`. PR vers `main` ouverte, sans merge, sans tag, sans release (garde-fou du
jalon : aucune release gouvernance avant la clôture de `fiabilite-v1.0`). Rapport :
`.planning/missions/2026-09-27-gouvernance-44.md`.

### Phase 45: Moteur — hook central par rôle et gates d'écriture

**Goal:** Un hook central lit `agent_type` et refuse par rôle (juge, worker, producteur) ; les gates d'écriture G1, G5, G6 et G7 refusent par `permissionDecision: deny`, G2 avertit ; chaque gate déclare son comportement fail-closed, se prouve en vie par un canary, mesure ses faux refus dans les deux sens, et la dérogation est nominative et journalisée.
**Requirements**: GATE-01..GATE-15 (posées au cadrage, `45-CONTEXT.md`, 2026-09-29)
**Depends on:** Phase 44 (les gates lisent le modèle et les états dérivés).
**Sources:** `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §5, §5.1, §5.2, D-05 (G7) ; `docs/superpowers/specs/2026-09-22-fabrique-agents-skills-design.md` §5, B-02 — **une mécanique, deux chantiers**.
**À envisager au cadrage** : comment un lab métier qui contient du code adhère-t-il (le détecteur
rend 2 et le moteur refuse l'écriture en 44) — origine : Phase 44, décision du head sous
délégation technique de Willy, session principale, 2026-09-28. **Tranché au cadrage** (P45-D-02 :
l'adhésion explicite l'emporte sur le signal de code ; Willy, AskUserQuestion session principale,
2026-09-29).
**Cadrage (2026-09-29)** : `45-CONTEXT.md`, décisions P45-D-01 à P45-D-21c.
- Arbitrages de Willy, AskUserQuestion session principale, 2026-09-29 : Q1 à Q6 et 13 décisions
  déléguées (reconfirmées après /clear), P45-D-21a (faux refus mesuré contre le modèle sur un lab
  non migré), P45-D-14a (table D-05 de la spec corrigée : `00-doctrine` n'est pas un lab).
- Décisions du manager, renversables : P45-D-01a, 03a, 03b, 05a, 05b, 06a, 06b, 12a, 20, 21,
  21b, 21c, et f5-etats.

**Plans:** 10 plans en 8 vagues. Ordre d'armement imposé par P45-D-03 : G6+G5 → G1 → G7 → rôle,
G2 en avertissement dès la vague 1. Plan-check frais PASSED au tour 6 (HEAD `4632c9b`), après
5 révisions chirurgicales. Quatre plans portent un `checkpoint:decision` borné, à trancher à
l'exécution : 45-02 (F10), 45-04 (F8), 45-05 (F6), 45-08 (F9).

**Exécution (2026-09-30 → 2026-10-01)** : mission `vf-dev-manager-p45-exec`, rapport
`.planning/missions/2026-09-30-gouvernance-45-exec.md`. 10/10 plans livrés ; revue et audit en deux
tours, corrections en 8 quick (kc3, lb4, fxa, 5xc, dzl, kp5, m8c, owx). Arbitrages de Willy,
AskUserQuestion session principale : F10, F7a, F8, A3, F6, F7b, F9 = f9-allowlist, rejeux réels
(2026-09-30) ; Q-ARM, oui pour les quatre étapes d'armement et découplage des suites (2026-09-30) ;
Q-G6 = (b), G6 protège les scripts du hook (2026-10-01). Rejeu réel final de l'étape 4
(`45-REJEU-FINAL.md`, 708debcb) : 0 faux refus, 0 faux accept, empreintes identiques. Armement en
cascade : G6+G5 (3d06e503), G1 (bf6cfa87), G7 (b6609fa6), rôle (239df76d) ; G2 avertit.
`planning-core` v2.9.0 sans release. Vérification (`45-VERIFICATION.md`) : 15/15 — GATE-15 (suites
en CI Linux sur l'état armé) prouvé par la CI de la PR #124 et validé par Willy (message en session
principale, 2026-10-01 : « clore ») ; GATE-09 au texte amendé F9 (allowlist).

**Clôture (2026-10-01 → 2026-10-02)**, à la demande de Willy (message en session principale,
2026-10-01 : « clore mais avant fait les audit de securité et apres une mise a jour doc », puis
« re mapping ») : audit de sécurité final en 4 tours, verdict SECURED (corrections F-01..F-03,
N-01..N-05, N2-01, N3-01..N3-02 dans les quick urj, wtd, 1dv, 3rx ; résidus déclarés en limites (z) à
(al) de `modele-cycles.md`) ; flake d'horloge MUT-PUCE-REGEX-CHAMP rendu déterministe (quick qq9) ;
documentation produit mise à jour après `--verify-only` ; cartographie `.planning/codebase/`
rafraîchie ; `main` (v2.68.0) intégrée par merge (d19835c5). Rejeux réels répétés après chaque tour
de code : 0 faux refus, 0 faux accept, empreintes identiques.

Plans:
**Wave 1**

- [x] 45-01-PLAN.md — socle : commande enregistrée fail-closed (adhésion décidée sans python3), lanceur `planning-hook.sh` et cœur Python, G2 en avertissement, zéro régression dev (GATE-01, 02, 03, 08, 10, 15)
- [x] 45-02-PLAN.md — levée du refus de la 44 pour un lab métier à code adhérent, trois branches de régression (GATE-14, 11, 15)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 45-03-PLAN.md — preuves d'armement : canary de CI et de session, outil de rejeu et `rejeu-reel.sh` (empreinte de tout l'arbre) (GATE-12, 13, 03, 10, 15)
- [x] 45-04-PLAN.md — entonnoir armed/observe/dérogation, G5 et commande qui pose `VERDICT.md` (GATE-05, 11, 02, 13, 15)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 45-05-PLAN.md — étape 1 : G6, canary, faux refus dans les deux sens, armement mécanique de G6+G5 (GATE-04, 05, 11, 12, 13, 15)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 45-06-PLAN.md — étape 2 : G1, contrôle croisé avec le recalcul, classification du modèle totale, armement à zéro (GATE-06, 12, 13, 15)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 45-07-PLAN.md — étape 3 : G7 (prédicat littéral), amendement de la table D-05 de la spec, armement à zéro (GATE-07, 12, 13, 15)

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 45-08-PLAN.md — hook par rôle : rôle dérivé des prédicats I5/I6, contrôle croisé avec `check-agents.sh` (GATE-09, 10, 02, 15)

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 45-09-PLAN.md — étape 4 : canary Agent et Task, rejeu réel, armement du rôle à zéro (GATE-09, 12, 13, 15)

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 45-10-PLAN.md — clôture : référence du modèle (limites (a) à (j)), coût de migration, `planning-core` v2.9.0 sans release, rejeu des gates (GATE-15, 03, 07, 08, 09, 11, 13)

### Phase 46: Moteur — gates de clôture et verdicts hachés

**Goal:** La clôture d'une tâche est refusée quand un livrable déclaré manque (G3) ou qu'un constat du verdict échoue (G4) ; un rapport de sous-agent sans sortie brute est refusé (G4′) ; `VERDICT.md` porte le hash de l'artefact jugé et un numéro de tentative ; `FileChanged` trace toute écriture surveillée (D1) ; au premier cycle, le canary joue la **sortie piégée** que l'initialisation a préparée pour chaque juge, et signale le juge qui ne la refuse pas (C-16).
**Requirements**: CLOT-01..CLOT-12 (posées au cadrage, `46-CONTEXT.md`, 2026-10-03)
**Depends on:** Phase 45.
**Sources:** `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §5 (G3, G4, G4′, D1), §10, D-02 (le juge ne bloque que sur ses constats) ; `docs/superpowers/specs/2026-09-23-initialisation-lab-design.md` C-16, §10 (préparer la preuve sans l'exécuter, B-01).
**À envisager au cadrage** : un état de transition « à clore » pour le cas « verdict passé,
SUMMARY absent » (le §3.1 ne le nomme pas, la Phase 44 le rend `indéterminé` par défaut,
P44-D-08) — origine Phase 44, décision (a), head sous délégation technique de Willy, session
principale, 2026-09-28. **Tranché au cadrage** (P46-D-04 : neuvième état `à clore`, non terminal ;
Willy, AskUserQuestion session principale, 2026-10-03).
**Cadrage (2026-10-03)** : `46-CONTEXT.md`, décisions P46-D-01 à P46-D-19 (plus 02a, 02b, 03a, 03b,
06a, 07a, 10a), mission `vf-dev-manager-p46-cadrage`. Faits : `46-RECHERCHE-HOOKS.md` (Claude Code
2.1.288) et `46-SCOUTING.md`.
- Arbitrages de Willy, AskUserQuestion session principale, 2026-10-03 : Q1 à Q8 (recommandation
  suivie, Q7 = b) puis Q9 (G4′ limité aux workers et producteurs qui ont Bash, P46-D-02b). Fait
  structurant : `TaskCompleted` n'existe pas par défaut sur les modèles récents ; G3/G4 passent en
  `PreToolUse` sur l'écriture de `CLOTURE.md`/`SUMMARY.md` (P46-D-01), la spec §5 est amendée.
- Décisions du manager, renversables : P46-D-02a, 03a, 03b, 06a, 07a, 09 à 19, 10a.
- Le rejeu réel des étapes 5 et 6 sur `~/jarvis-keystone` et `~/BusinessFlow-Lab` **n'est pas
  autorisé par le planning** : le checkpoint de 46-11 le demande à Willy au moment de l'exécution.
**Plans:** 12 plans en 9 vagues. Ordre d'armement P46-D-11 : (G3 + G4, empreintes comprises) →
G4′ ; D1 n'est jamais armé. Plan-check frais : tour 1 (deux checkers, objectif et exécutabilité)
0 bloquant ; révision 1 (Q9, mode dégradé, codes de sortie des vérifications, replis sûrs) ; tour 2
PASSED ; révision 2 (formulation du checkpoint de rejeu, consigne d'exécution des vérifications en
session isolée). Deux plans `autonomous: false` portent un checkpoint humain borné : 46-11 (rejeu
réel, étape 5) et 46-12 (porte de G4′, étape 6).

Plans:
**Wave 1**

- [x] 46-01-PLAN.md — modèle côté pose : prédicat « livrable présent », deux empreintes (plan A3 + livrables), plafond de 3 tentatives (CLOT-01, 03, 05)
- [x] 46-02-PLAN.md — amendements de la spec moteur (§3.1, §5, §5.1-1, §10) et texte de la note ROADMAP de la 47 (CLOT-12)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 46-03-PLAN.md — recalcul : R4 « absent ou vide », vérification des deux empreintes, état `à clore` (CLOT-01, 03, 04)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 46-04-PLAN.md — câblage : une commande, un mode par événement, `SubagentHandback` au matcher, canary, inventaire des hooks (CLOT-09, 11, 12)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 46-05-PLAN.md — G3 et G4 en observation, fail-closed, banc de clôture et mutation d'armement (CLOT-01, 02, 03, 09, 10)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 46-06-PLAN.md — G4′ en observation : `PreToolUse(SubagentHandback)` + repli `SubagentStop`, agents qui ont Bash (CLOT-06, 09, 12)

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 46-07-PLAN.md — D1 : `FileChanged`/`watchPaths`, journal protégé par G6, réconciliation par hash au `SessionStart` (CLOT-07, 09, 11)
- [x] 46-08-PLAN.md — outil de rejeu étendu aux étapes 5 et 6, constructeurs G3/G4/G4′ (CLOT-10)

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 46-09-PLAN.md — canary de juge C-16 : contrat de la sortie piégée, vérificateur déterministe, « juge sans preuve » (CLOT-08)
- [x] 46-10-PLAN.md — zéro régression lab dev par événement, coût hors adhésion mesuré (CLOT-11)

**Wave 8** *(blocked on Wave 7 completion)*

- [ ] 46-11-PLAN.md — étape 5 : autorisation du rejeu réel demandée à Willy, banc, canary, rejeu en lecture seule, armement de G3 + G4 (CLOT-10)

**Wave 9** *(blocked on Wave 8 completion)*

- [ ] 46-12-PLAN.md — étape 6 : porte de G4′, rejeu, armement, référence et limites, `planning-core` v2.10.0 sans release (CLOT-10, 12)

### Phase 47: Moteur — baux générationnels et jeton monotone

**Goal:** Un bail générationnel porte les fichiers d'état réécrits en place, au fichier près ; son numéro de génération est un jeton monotone vérifié par le hook **et** par l'écrivain, qui rejette l'écriture périmée d'une session revenue, d'un cron ou d'un sous-agent en fan-out ; à la clôture, G2′ refuse ce qui a bougé hors du bail sans amendement.
**Requirements**: TBD (posés au cadrage)
**Depends on:** Phase 46 (G2′ se branche sur le même événement `TaskCompleted` que G3/G4 ; il vit ici parce qu'il consomme le bail).
**Note du cadrage de la 46 (P46-D-19, 2026-10-03)** : la prémisse « même `TaskCompleted` que G3/G4 » ne tient plus. La 46 a porté G3/G4 en `PreToolUse` sur l'écriture de `CLOTURE.md`/`SUMMARY.md` (P46-D-01, Willy, AskUserQuestion session principale, 2026-10-03), parce que `TaskCompleted` n'existe pas par défaut sur les modèles récents (`46-RECHERCHE-HOOKS.md` §0). Le point d'accroche de G2′ se re-décide au cadrage de la 47.
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
