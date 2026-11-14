# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Milestones

- ✅ **vfdo-v1.0** — Module dev-orchestrator (Phase 1) — clôturé 2026-06-04
- ✅ **install-ux-v1.0** — Phases 2-6 — clôturé 2026-06-05 (plugin + skill à toggles + scope) — release `v2.4.0`
- ✅ **dev-doctrine** — Phases 7-8 — doctrine dev (SOLID/DRY/KISS/YAGNI/Clean Archi/Clean Code/TDD) + consolidation des doublons qualité — clôturé 2026-07-07 — release `v2.20.0`
- ✅ **memory-swarm-rnd** — Phase 9 — R&D : transposition du modèle mémoire + patterns swarm de jcode — spike GO, shippé `v2.28.0` (ADR-052 mémoire vivante + ADR-053 swarm)
- ✅ **gsd-migration** — Phases 10-11 — clos 2026-07-26, release `v2.39.0` — migration du package GSD `get-shit-done-cc` → `@opengsd/gsd-core@^1` (VOC-02)
- ✅ **vf-routing** — Phases 12-14 — clos 2026-07-26, release `v2.37.0` — routage fin des intentions (verbes `/vf-*` à l'origine ; carte d'intention agentique depuis la bascule v2.33.0), couverture complète des skills GSD, pont spec → feuille de route, et frontière d'altitude avec le moteur de planning GSD
- ✅ **agentique-v1.0** — Phases 15→29 (18 et 25 reportées) — **clos 2026-08-15**, releases `v2.40.0` → `v2.52.0` (détail : `.planning/milestones/agentique-v1.0-ROADMAP.md`)
- ✅ **fiabilite-v1.0** — « ce qui survit » — Phases 30-35, 37-41.4 + Phases 18 et 25 héritées — **clos 2026-10-08**, releases `v2.53.0` → `v2.69.0` (plans 41-07 à 41-13 confiés à Willy, hors clôture ; détail : `.planning/milestones/fiabilite-v1.0-ROADMAP.md`)
- 📋 **equipe-produit-v1.0** — « l'équipe produit : rôles humains, amont produit, état partagé » — Phases 57-66 — **inscrit 2026-10-08**, prochain jalon exécuté (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08) ; spec `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md`, germe `SEED-001`
- 📋 **ecc-inspiration-v1.0** — « ce qu'on emprunte à ECC » — Phases 51-56 — **inscrit 2026-09-25** ; exécution après la clôture de `fiabilite-v1.0`, en parallèle du jalon de Willy (arbitrage Samuel, AskUserQuestion session principale, 2026-09-25) ; étude : `.planning/research/2026-09-25-ecc-inspiration-etude.md`
- 📋 **vibeflow-v2.0** — « le cockpit VibeFlow » — Phases 67-81 — **inscrit 2026-11-01** ; publié au 2026-11-11 : Phase 67 en `v2.75.0`, Phases 68 à 72, 71.5 et 78 en `v2.76.0` ; Phases 73 à 77, 79 et 80 cadrées et planifiées le 2026-11-11 (93 plans), 81 reportée ; ordre, arbitrages et sources : section du jalon plus bas. Texte d'origine des trois entrées : `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md`

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Origine des Phases 23 à 25 (blockquote ; le texte est aussi dans .planning/milestones/fiabilite-v1.0-ROADMAP.md) -->

## Phases

### État des phases — checklist lue par le moteur

> **Ne pas retirer.** C'est la SEULE forme que `@opengsd/gsd-core` lit pour établir qu'une phase
> est terminée (`roadmap.cjs` → `checkboxPattern`) ; il la coche lui-même à la clôture d'une phase
> vérifiée. La table `## Progress` plus bas, elle, n'est lue par aucun outil : elle est rédigée
> pour les humains et les deux doivent rester d'accord.
>
> Cette checklist a été posée le 2026-08-01, après coup : le ROADMAP n'en avait jamais eu, si bien
> que le moteur voyait **zéro** phase terminée et rendait des compteurs faux
> (`completed_phases: 10`, `current_phase: 19` alors que la 22 était livrée). C'est aussi ce qui
> rattrape les **20 plans sans SUMMARY** des Phases 11 à 14 : `roadmap.cjs` fait explicitement
> primer la case cochée sur le disque, « pour les phases terminées avant le tracking GSD, qui
> n'ont pas les paires PLAN/SUMMARY ». Ces 4 phases sont shippées, chacune avec sa release.

- [x] Phase 1: dev-orchestrator (completed 2026-06-04)
- [x] Phase 2: Manifeste & résolveur (completed 2026-06-04)
- [x] Phase 3: Engine scope-aware (completed 2026-06-05)
- [x] Phase 4: Skill /vibeflow-install + auto-lancement (completed 2026-06-05)
- [x] Phase 5: Packaging plugin (completed 2026-06-05)
- [x] Phase 6: dev-orchestrator first-use (completed 2026-06-05)
- [x] Phase 7: Philosophies de dev (completed 2026-07-07)
- [x] Phase 8: Consolidation des doublons (completed 2026-07-07)
- [x] Phase 9: Spike transposition jcode (mémoire + swarm) (completed 2026-07-22)
- [x] Phase 10: Étude & faisabilité migration GSD (completed 2026-07-26)
- [x] Phase 11: Intégration migration GSD (completed 2026-07-26)
- [x] Phase 12: Routage fin & couverture complète des verbes (completed 2026-07-25)
- [x] Phase 13: Pont spec → feuille de route (completed 2026-07-26)
- [x] Phase 14: Frontière d'altitude planning-core / moteur GSD (completed 2026-07-25)
- [x] Phase 15: Collaboration inter-équipes dev ↔ design (completed 2026-07-27)
- [x] Phase 16: Cloisonnement complet des dispatches d'agents (completed 2026-07-27)
- [x] Phase 17: Signaux de démarrage du moteur de dev (completed 2026-07-28)
- [x] Phase 18: Survie du ledger d'exigences à la clôture de jalon (completed 2026-08-18)
- [x] Phase 19: Migration du moteur GSD pilotée par /vf-update (completed 2026-07-28)
- [x] Phase 20: Fluidité du flux de dev sans perte de qualité (completed 2026-07-31)
- [x] Phase 21: Alignement du moteur GSD sur gsd-core 1.9.0 (completed 2026-07-31)
- [x] Phase 22: Hygiène documentaire (completed 2026-07-31)
- [x] Phase 23: Couplage explicite au moteur GSD
- [x] Phase 24: Activation et mesure du moteur GSD (completed 2026-08-05)
- [x] Phase 25: Budget d'instructions (completed 2026-09-16)
- [x] Phase 26: Manuel utilisateur VibeFlow (manual/) (completed 2026-08-02)
- [x] Phase 27: Parallélisation d'exécution (completed 2026-08-06)
- [x] Phase 28: Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur (completed 2026-08-15)
- [x] Phase 29: Distiller les gains ICM (G1-G5) (completed 2026-08-15)
- [x] Phase 30: Portabilité Windows II (completed 2026-08-16)
- [x] Phase 31: Manifeste d'install + dry-run (issue #20) (completed 2026-08-16)
- [x] Phase 32: Durcissement du driver-lock (completed 2026-08-17)
- [x] Phase 33: Watchdog & notifications des missions (completed 2026-08-17)
- [x] Phase 34: Gaps agency-agents & cadrage skill-installer (completed 2026-09-15)
- [x] Phase 35: Ré-armement worktree (CLOSE 2026-08-26)
- [x] Phase 36: RÉSERVÉ
- [x] Phase 37: Portabilité multi-runtime (completed 2026-08-28)
- [x] Phase 38: Portabilité multi-runtime
- [x] Phase 39: Workstreams
- [x] Phase 40: vibeflow-head
- [x] Phase 40.1: Révision ADR-029 et du gate du budget d'instructions
- [x] Phase 41: Posture de protection du dépôt (plans 41-07 à 41-13 confiés à Willy, hors clôture de `fiabilite-v1.0` — arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 ; PR #80, `v2.64.0` ; ligne d'origine : `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md`)
- [x] Phase 41.1: Gates de planning workstream-aware
- [x] Phase 41.2: Choisir la partition du planning au démarrage d'un lab (complete 2026-10-02)
- [x] Phase 41.3: Sobriété de méthode (complete 2026-09-30)
- [x] Phase 41.4: Emprunts Pocock (complete 2026-10-06)
- [ ] Phase 51: Snapshot de planning avant compaction (PreCompact) (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 52: Télémétrie d'usage des skills et agents, et coût de mission (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 53: Apprentissage adossé à l'observation — preuves dans la mémoire vivante (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 54: Audit du harness comme surface d'attaque (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 55: Installeur et mémoire portables entre runtimes (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 56: Packs de règles par langage (module optionnel) (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [x] Phase 57: Verrou de driver par compartiment (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-12
- [x] Phase 58: Rôles de poste — installeur, profils solo / product / dev (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-22
- [x] Phase 59: Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-27
- [x] Phase 60: Gate architecture avant découpage et validation des phases proposées (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-29
- [x] Phase 61: Collaboration à deux humains — divergence armée, preuve sur lab réel (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-29
- [x] Phase 62: Décision sur l'approche plateforme, sur preuve (inscrite 2026-10-08, jalon equipe-produit-v1.0) — close 2026-10-29
- [ ] Phase 63: Règles produit empruntées à AIDD (inscrite 2026-10-29, jalon equipe-produit-v1.0)
- [ ] Phase 64: Contrôles après exécution branchés en nœuds du plan de bataille (inscrite 2026-10-29, jalon equipe-produit-v1.0)
- [ ] Phase 65: Révision des règles qui brident l'efficacité des agents (inscrite 2026-10-29, jalon equipe-produit-v1.0)
- [ ] Phase 66: Grille de sévérité des juges et convergence des boucles de revue (inscrite 2026-10-29, jalon equipe-produit-v1.0)
- [x] Phase 67: Cockpit floorplan sur socle partagé (inscrite 2026-11-01, jalon vibeflow-v2.0) — complete 2026-11-03
- [x] Phase 68: Embarquer vf-signal sur le socle partagé (inscrite 2026-11-01, jalon vibeflow-v2.0) — complete 2026-11-04 : 13/13 plans, VFSG-01..13 cochées, publiée en `v2.76.0`
- [x] Phase 69: Suivi du travail en cours dans le cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-04
- [x] Phase 70: Finitions UI du cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-04 : 12/12 plans, UIFN-10 décochée, publiée en `v2.76.0`
- [x] Phase 71: Terminal intégré au cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-05 : TERM-01..12 cochées, publiée en `v2.76.0`
- [x] Phase 71.5: Réexamen du design system du cockpit (INSERTED, inscrite 2026-11-05, jalon vibeflow-v2.0) — complete 2026-11-06 : mission design, sans plan GSD ni exigence au ledger, publiée en `v2.76.0`
- [x] Phase 72: Lancer du travail depuis les cartes du cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-06 : 16/16 plans, LANC-12 décochée, publiée en `v2.76.0`
- [ ] Phase 73: Gouvernance au cockpit — arbitrages en attente, worktrees et verrous (inscrite 2026-11-03, jalon vibeflow-v2.0) — cadrée et planifiée le 2026-11-11 (11 plans, REGI-01..17)
- [ ] Phase 74: L'équipe dans le temps — swim-lanes, coût, replay (inscrite 2026-11-03, jalon vibeflow-v2.0) — cadrée et planifiée le 2026-11-11 (10 plans, 6 vagues, TEMP-01..12)
- [ ] Phase 75: L'activité posée sur le code — hotspots, couplage, gardes, empreinte (inscrite 2026-11-03, jalon vibeflow-v2.0) — cadrée et planifiée le 2026-11-11 (12 plans, 9 vagues, ACTV-01..12)
- [ ] Phase 76: Traçabilité au cockpit — exigences, décisions, mémoire (inscrite 2026-11-03, jalon vibeflow-v2.0 ; cadrée et planifiée 2026-11-11, 9 plans)
- [ ] Phase 77: Santé de la méthode et synthèse — jauges, dernière visite, burn-up (inscrite 2026-11-03, jalon vibeflow-v2.0) — planifiée 2026-11-11 (8 plans)
- [x] Phase 78: Git dans le cockpit — en-tête, graphe des worktrees et branches, données Git (inscrite 2026-11-05, jalon vibeflow-v2.0) — complete 2026-11-06 : 11/11 plans, GITC-01..14 cochées, publiée en `v2.76.0`
- [ ] Phase 79: Socle du cockpit — une collecte, un flux, une route d'état (inscrite 2026-11-11, jalon vibeflow-v2.0) — 22/22 plans faits (SOCL-24 clos par la sonde S0)
- [ ] Phase 80: Trois onglets, trois formes — Projet en couloirs, clavier, navigation (inscrite 2026-11-11, jalon vibeflow-v2.0) — 21/21 plans faits (2026-11-14, branche feat/phase-80-trois-formes) ; FORM-17 attend la CI Linux
- [ ] Phase 81: Agir sur une session depuis le cockpit (inscrite 2026-11-11, jalon vibeflow-v2.0, reportée : `AUDC-Q3` tranchée « plus tard » le 2026-11-11)

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ vfdo-v1.0 — Module dev-orchestrator (Phase 1) — SHIPPED 2026-06-04 -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ install-ux-v1.0 — Phases 2-6 — clôturé 2026-06-05, release `v2.4.0` -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ dev-doctrine — Phases 7-8 — clôturé 2026-07-07, release `v2.20.0` -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ memory-swarm-rnd — Phase 9 — spike GO, shippé `v2.28.0` -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ gsd-migration — Phases 10-11 — clos 2026-07-26, release `v2.39.0` -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ vf-routing — Phases 12-14 — clos 2026-07-26, release `v2.37.0` -->

## Progress


| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — table Progress, Phases <= 41.4 et ordre d exécution (lignes de table, aucune lue par un outil) -->
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — table Progress, lignes d'origine des Phases 41 et 57 à 62 (équipe-produit-v1.0 et fiche de la 41), et des Phases 67 à 72 et 78 avant leur raccourcissement -->
| 67. Cockpit floorplan sur socle partagé | vibeflow-v2.0 | 7/7 | Complete — PR #187, release `v2.75.0` | 2026-11-03 |
| 68. Embarquer vf-signal sur le socle partagé | vibeflow-v2.0 | 13/13 | Complete — PR #199, release `v2.76.0` | 2026-11-04 |
| 69. Suivi du travail en cours dans le cockpit | vibeflow-v2.0 | 9/9 | Complete — PR #198, release `v2.76.0` | 2026-11-04 |
| 70. Finitions UI du cockpit | vibeflow-v2.0 | 12/12 | Complete — PR #200, UIFN-10 décochée, release `v2.76.0` | 2026-11-04 |
| 71. Terminal intégré au cockpit | vibeflow-v2.0 | 11/11 | Complete — PR #203 et #209, release `v2.76.0` | 2026-11-05 |
| 71.5. Réexamen du design system du cockpit | vibeflow-v2.0 | mission design, sans plan GSD | Complete — PR #213, release `v2.76.0` | 2026-11-06 |
| 72. Lancer du travail depuis les cartes du cockpit | vibeflow-v2.0 | 16/16 | Complete — PR #214, LANC-12 décochée, release `v2.76.0` | 2026-11-06 |
| 73. Gouvernance au cockpit — arbitrages en attente, worktrees et verrous | vibeflow-v2.0 | 11/11 | In progress | - |
| 74. L'équipe dans le temps — swim-lanes, coût, replay | vibeflow-v2.0 | 6/10 | In Progress | - |
| 75. L'activité posée sur le code — hotspots, couplage, gardes, empreinte | vibeflow-v2.0 | 12/12 | Complete | 2026-11-14 |
| 76. Traçabilité au cockpit — exigences, décisions, mémoire | vibeflow-v2.0 | 9/9 | Complete    | - |
| 77. Santé de la méthode et synthèse — jauges, dernière visite, burn-up | vibeflow-v2.0 | 0/8 | Planned | - |
| 78. Git dans le cockpit | vibeflow-v2.0 | 11/11 | Complete — PR #216, release `v2.76.0` | 2026-11-06 |
| 79. Socle du cockpit — une collecte, un flux, une route d'état | vibeflow-v2.0 | 22/22 | In progress — plans faits, lot en cours | - |
| 80. Trois onglets, trois formes — Projet en couloirs, clavier, navigation | vibeflow-v2.0 | 8/21 | In progress — segment a fusionné (PR #237) | - |

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ agentique-v1.0 — Durcissement du moteur d'équipes agentique (Phases 15→29, 18 et 25 reportées) — SHIPPED 2026-08-15 -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-10-13.md — ✅ fiabilite-v1.0 — « ce qui survit » (Phases 30-35, 37-41.4 + 18 et 25 héritées) — SHIPPED 2026-10-08, releases `v2.53.0` → `v2.69.0` -->

## Phase 41 — chaîne de mesures confiée à Willy (hors clôture de fiabilite-v1.0)

### Phase 41: Posture de protection du dépôt
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 41 (section « Phase 41 — chaîne de mesures… » : but, critères de succès, plans 41-01 à 41-19) -->

**État :** complete hors 41-07 à 41-13, confiés à Willy (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02) — PR #80, release `v2.64.0`. Fiche entière (but, critères de succès, plans) : `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md`.

## 📋 Milestone ecc-inspiration-v1.0 — « ce qu'on emprunte à ECC » (Phases 51-56)

> Sections 51 à 56 et introduction du jalon archivées dans `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md`, à réinsérer au cadrage de la 51 (`gsd-discuss-phase 51` lit `### Phase 51:` ; la checklist 51-56 et l'entrée `## Milestones` restent ici).

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — jalon ecc-inspiration-v1.0 : introduction et Phases 51 à 56, aucun dossier de phase, non démarré (réinsérer au cadrage de la 51) -->

**Phase 52 — note de la Phase 74 (P74-D-22), à lire au cadrage de la 52 :** Le calcul des jetons est celui de l'index de la Phase 79 (somme de `message.usage` dédoublonnée par identifiant de message) ; la 52 le réutilise au lieu d'en écrire un second (P74-D-22).

## 📋 Milestone equipe-produit-v1.0 — « l'équipe produit » (Phases 57-66)

**État :** jalon ouvert ; Phases 57 à 62 complete, Phases 63 à 66 inscrites le 2026-10-29, non cadrées. But du jalon, critères de succès (spec §9), ce qu'il ne fait pas, collisions avec le jalon de Willy et critère transverse (QUAL-01) : `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md`.

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — equipe-produit-v1.0 : introduction -->

### Phase 57: Verrou de driver par compartiment
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 57 (corps) -->
**État :** complete 2026-10-12 — 16/16 plans, PR #152, release `v2.70.0` ; corps (but, exigences, dépendances) dans l'archive ci-dessus.

### Phase 58: Rôles de poste — installeur, profils solo / product / dev
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 58 (corps) -->
**État :** complete 2026-10-22 — 12/12 plans, release `v2.71.0` ; corps (but, exigences, dépendances) dans l'archive ci-dessus.

### Phase 59: Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 59 (corps) -->
**État :** complete 2026-10-27 — 8/8 plans, PRDT-01..12 cochées, release `v2.73.0` ; corps (but, exigences, dépendances) dans l'archive ci-dessus.

### Phase 60: Gate architecture avant découpage et validation des phases proposées
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 60 (corps) -->
**État :** complete 2026-10-29 — 9/9 plans, ARCG-01 et ARCG-09 partielles, release `v2.74.0` ; corps (but, exigences, dépendances) dans l'archive ci-dessus.

### Phase 61: Collaboration à deux humains — divergence armée, preuve sur lab réel
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 61 (corps) -->
**État :** complete 2026-10-29 — 8/8 plans, COLB-08 décochée, COLB-09 partielle, release `v2.74.0` ; corps (but, exigences, dépendances) dans l'archive ci-dessus.

### Phase 62: Décision sur l'approche plateforme, sur preuve
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 62 (corps) -->
**État :** close 2026-10-29 — 1/1 plan, décision A (approche C différée), réexamen 2027-01-31, sans release ; corps (but, exigences, dépendances) dans l'archive ci-dessus.

### Phase 63: Règles produit empruntées à AIDD
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 63 (corps ; à réinsérer au cadrage de la phase) -->
**État :** inscrite 2026-10-29, non cadrée, aucun plan ; corps (but, sources, hors périmètre) dans l'archive ci-dessus, à réinsérer au cadrage.

### Phase 64: Contrôles après exécution branchés en nœuds du plan de bataille
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 64 (corps ; à réinsérer au cadrage de la phase) -->
**État :** inscrite 2026-10-29, non cadrée, aucun plan ; corps (but, sources, hors périmètre) dans l'archive ci-dessus, à réinsérer au cadrage.

### Phase 65: Révision des règles qui brident l'efficacité des agents
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 65 (corps ; à réinsérer au cadrage de la phase) -->
**État :** inscrite 2026-10-29, non cadrée, aucun plan ; corps (but, sources, hors périmètre) dans l'archive ci-dessus, à réinsérer au cadrage.

### Phase 66: Grille de sévérité des juges et convergence des boucles de revue
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 66 (corps ; à réinsérer au cadrage de la phase) -->
**État :** inscrite 2026-10-29, non cadrée, aucun plan ; corps (but, sources, hors périmètre) dans l'archive ci-dessus, à réinsérer au cadrage.

## 📋 Milestone vibeflow-v2.0 — « le cockpit VibeFlow » (Phases 67-81)

**Milestone Goal :** un saut d'usage visible pour qui installe VibeFlow : un cockpit qui montre le projet, le code
et qui est au travail, dans tout lab GSD, sur un socle partagé avec le panneau compact `vf-signal`. Le cockpit
floorplan remplace le module `vf-cockpit` (page Mermaid, branche `feat/vf-cockpit-module`, jamais mergée). Entrée du cadrage :
`.planning/notes/2026-11-01-cockpit-facettes.md` ; savoir technique : skill local `spike-findings-vibeflow-os`,
`.planning/spikes/WRAP-UP-SUMMARY.md` (spikes 002 à 006) et `docs/research/2026-11-01-etude-floorplan-cockpit.md`.

**Publié au 2026-11-11 :** la Phase 67 en `v2.75.0` (2026-11-03) ; les Phases 68, 69, 70, 71, 71.5, 72 et 78 en `v2.76.0` (2026-11-06, PR de release #217,
module `cockpit` v1.4.0). Rien n'est publié depuis : gel des publications (décision de Samuel du 2026-11-08, `.planning/missions/2026-11-08-recette-correctifs.md`) ;
le travail postérieur vit sur `release/v2.77.0` (PR #226).

**Inscription :** 2026-11-01 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-01) ; Phases 69, 71 et 72 inscrites le 2026-11-03 avec leur ordre. Paragraphes d'origine (dont `SEED-004` et la numérotation) : `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md`.

**Phases 73 à 77 :** inscrites le 2026-11-03 depuis la recherche `.planning/notes/2026-11-03-cockpit-idees-recherche.md`
(arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 : « toutes les propositions sont bien, intègre-les au jalon », puis « 5 phases thématiques (Recommandé) »).
**Ordre du jalon, mis à jour :** 69 → 73 → 68 → 70 → 71 → 72 → 74 → 75 → 76 → 77 (même session : « Gouvernance tôt, reste après
72 (Recommandé) »). Contraintes communes : traces locales seulement, aucune lecture réseau, lecture seule, un ajout = un retrait.

**Audit du 2026-11-10 :** audit complet du cockpit, versé le 2026-11-11 dans `.planning/research/2026-11-10-audit-cockpit-etude.md` (demande de Samuel,
session principale Claude Code, 2026-11-10 : « verses l'audit dans le planning pour cadrer les prochaines phases […] Et que ça soit corrigé
et qu'on applique les choses qui ont été vues »). Il ajoute une source de cadrage aux Phases 73 à 77 sans réécrire leurs buts, et inscrit
les Phases 79 (socle), 80 (formes) et 81 (actions sur une session, reportée). Ses corrections immédiates forment
le lot 0, mission hors phase (`2026-11-10-audit-cockpit/LOT-0-MANDAT.md`) ; le suivi ligne à ligne se tient dans
`2026-11-10-audit-cockpit/REGISTRE.md`. **Ordre recommandé pour la suite du jalon** (décision déléguée par Samuel, message session
principale, 2026-11-08, option recommandée) : lot 0 → 79 et 80 en parallèle → 73 (ses plans consomment des contrats des 79 et 80 : A10-A11, A30-A32, `VF_SURCOUCHES`, `VF_ONGLETS`) → 74 → 75 → 76 → 77 ;
81 seulement si Samuel le décide (`AUDC-Q3`). **Décisions de fond tranchées le 2026-11-11** (registre § 5.1, Samuel retenant l'avis de
la session principale) : fork du moteur assumé, index des sessions sur disque avec fenêtre de 24 h, `claude agents` en source de
référence, Phase 81 reportée.

### Phase 67: Cockpit floorplan sur socle partagé
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 67 (corps) -->
**État :** complete 2026-11-03 — PR #187, CKPT-01..12 cochées, publiée en `v2.75.0` ; corps dans l'archive ci-dessus.

### Phase 68: Embarquer vf-signal sur le socle partagé
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 68 (corps) -->
**État :** complete 2026-11-04 — PR #199, VFSG-01..13 cochées, publiée en `v2.76.0` ; corps dans l'archive ci-dessus.

### Phase 69: Suivi du travail en cours dans le cockpit
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 69 (corps) -->
**État :** complete 2026-11-04 — PR #198, CKPT-13..28 cochées, publiée en `v2.76.0` ; corps dans l'archive ci-dessus.

### Phase 70: Finitions UI du cockpit
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 70 (corps) -->
**État :** complete 2026-11-04 — PR #200, UIFN-01 à 09 et 11 à 14 cochées, UIFN-10 décochée, publiée en `v2.76.0` ; corps dans l'archive ci-dessus.

### Phase 71: Terminal intégré au cockpit
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 71 (corps) -->
**État :** complete 2026-11-05 — PR #203 et #209, TERM-01..12 cochées, publiée en `v2.76.0` ; corps dans l'archive ci-dessus.

### Phase 71.5: Réexamen du design system du cockpit (INSERTED)
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 71.5 (corps) -->
**État :** complete 2026-11-06 — PR #213, mission design sans plan GSD ni exigence au ledger, publiée en `v2.76.0` ; corps dans l'archive ci-dessus.

### Phase 72: Lancer du travail depuis les cartes du cockpit
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 72 (corps) -->
**État :** complete 2026-11-06 — PR #214, LANC-01..11 cochées, LANC-12 décochée, publiée en `v2.76.0` ; corps dans l'archive ci-dessus.

### Phase 73: Gouvernance au cockpit — arbitrages en attente, worktrees et verrous

> **Cadrée le 2026-11-11** (`73-CONTEXT.md`, P73-D-01..36 : décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée, sur la direction « régie » retenue par Samuel le 2026-11-11, registre § 5.1). Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

**Goal:** Le cockpit montre ce qui attend une décision humaine (arbitrages en attente, reliés à leur phase et à ce qu'ils bloquent), qui tient le verrou de driver, quels worktrees et branches existent avec leur travail non commité, et l'alerte du watchdog posée sur le nœud de mission concerné. Forme ajoutée par l'audit du 2026-11-10 : l'onglet Équipe devient une régie — « À vous », « Au travail », « Terminé, à relire », « Au repos » — à la place de son canevas.
**Requirements**: REGI-01, REGI-02, REGI-03, REGI-04, REGI-05, REGI-06, REGI-07, REGI-08, REGI-09, REGI-10, REGI-11, REGI-12, REGI-13, REGI-14, REGI-15, REGI-16, REGI-17
**Depends on:** Phase 69 (objet `avancement`, collecteur `who`) ; lot 0 de l'audit (états lus des sessions, livré). Pas de blocage dur sur la Phase 79 (la régie lit le magasin de page de la 79 s'il existe, P73-D-02), mais ses plans consomment les contrats des Phases 79 et 80 : exécution après elles (jointure J1, 2026-11-13). Réutilise les routes de la Phase 78 pour les worktrees (P78-D-08). Pose les points d'accroche de la Phase 74 (P73-D-20).
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 9, 13, 4) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2, `REGISTRE.md` (AUDC-I01, I02, I03, I09, I10, I21, I34, I38, reste de D4 et M3, F2), `DESIGNS.md` § 3 ; `73-UI-SPEC.md`.
**Retraits:** le canevas de l'onglet Équipe ; le nom écrit trois fois ; la carte et le pli « Terminés depuis moins de 24 h » ; le panneau d'item d'Équipe et ses styles de bouton ; la section Santé injectée sur Équipe ; P70-D-20 / UIFN-14.

**Success Criteria** (what must be TRUE):
  1. L'onglet Équipe ne porte plus de canevas : quatre sections dans l'ordre, un agent qui attend en tête dans « À vous » et à sa place dans l'arbre ; aucun fichier du moteur vendorisé modifié.
  2. « À vous » réunit les sessions qui vous attendent et les phases en `human_needed`, classées par ce qu'elles retiennent en aval, « impact inconnu » plutôt qu'une estimation.
  3. Le tenant du verrou, l'alerte du watchdog (abandon, sans progrès) et les arbres de travail avec leur non commité se lisent sur la régie, sans appel git neuf ni champ brut du verrou dans la page.
  4. Le titre de l'onglet dit « (N) vous attendent » et survit aux autres écrivains du titre ; « ailleurs sur ce poste » ne montre que nombre et nom de lab, nom qui ne sort jamais de la page servie (témoin de non-fuite).
  5. « Terminé, à relire » se vide à la lecture, dans ce navigateur seulement, en 24 h au plus ; la seule action d'une ligne est « Lire le rapport ».
  6. La Phase 74 peut brancher frise et fiche par le registre de vues et l'événement d'ouverture sans retoucher un fichier de la 73.
  7. Toutes les suites du cockpit vertes sous macOS et Linux, les témoins du canevas re-pointés (aucun supprimé pour verdir), chaque exigence prouvée par un témoin rouge avant le code.
**Plans:** 11 plans

Plans:

- [x] 73-01-PLAN.md — Socle de la suite unique et module de gouvernance
- [x] 73-02-PLAN.md — `ailleurs()` et route `GET /api/vf/ailleurs`
- [x] 73-03-PLAN.md — Champs de gouvernance de who@2 dans la collecte, LR.1 à LR.6
- [x] 73-04-PLAN.md — Modèle de la régie (sans DOM), feuille, exports de 71
- [x] 73-05-PLAN.md — Page de la régie : adaptateur, accroches de la Phase 74, états de page
- [x] 73-06-PLAN.md — Compositeur du titre, pastille de favicon, état « lu »
- [x] 73-07-PLAN.md — Pied : arbres de travail, « ailleurs », non-fuite de bout en bout
- [x] 73-08-PLAN.md — Retrait du canevas d'Équipe, côté serveur et côté page
- [x] 73-09-PLAN.md — Correspondance LE → LR, témoins W23 et de page re-pointés
- [x] 73-10-PLAN.md — Tiroir hors d'Équipe, README, CHANGELOG, toutes les suites
- [x] 73-11-PLAN.md — Questions en attente des cadrages dans « À vous », décisions prises pour vous à part (REGI-17)

### Phase 74: L'équipe dans le temps — swim-lanes, coût, replay

> **Cadrée le 2026-11-11** — `74-CONTEXT.md`, P74-D-01 à P74-D-56, décisions déléguées par Samuel
> (message session principale, 2026-11-08), option recommandée ; spécification d'interface `74-UI-SPEC.md`. Inscrite le
> 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03). Planifiée le 2026-11-11 (10 plans, 6
> vagues), revalidée le même jour contre les Phases 79 (`673c879d`, A1 à A49), 73 (`b5abfeec`, P73-C1 à C5) et 80
> (`3e5db01f`) ; ce qui dépend d'un livrable non encore écrit porte « à revalider » dans le plan.

**Goal:** L'onglet Équipe montre les agents sur un axe de temps (une ligne par agent, colorée par nœud de DAG), le coût en jetons et en durée par mission, phase et agent, et rejoue une mission nœud par nœud avec un curseur temporel.
**Lecture du but (P74-D-01) :** but arbitré non réécrit (AUDC-V6). « Colorée par nœud de DAG » contredit `DESIGN.md` § 9 :
le nœud s'écrit sur la voie, la couleur reste aux trois états ; confirmé par Samuel (P74-D-46, arbitrage Samuel,
AskUserQuestion session principale, 2026-11-11 : « Suivre la règle de design (Recommandé) »). Fenêtre de 24 h au plus
(AUDC-Q2) : coût et relecture se lisent sur la fenêtre affichée. La relecture dérive l'état des nœuds des voies des agents
qui les portent (aucun horodatage de transition dans les DAG).
**Requirements**: TEMP-01, TEMP-02, TEMP-03, TEMP-04, TEMP-05, TEMP-06, TEMP-07, TEMP-08, TEMP-09, TEMP-10, TEMP-11, TEMP-12
**Depends on:** Phase 79 (contrats figés au commit `3119d82a`, C0 à C6 : index des transcripts sur disque avec segments, compteurs et jetons dédoublonnés par message ; route de frise ; extension du contrat de forme) ; Phase 73 (régie : ouverture de la fiche depuis une ligne, place de la bascule « Régie · Frise ») ; Phase 69 (onglet Équipe, lien agent ↔ nœud) ; Phase 80 (`VF_ONGLETS.aller('code')`, contrat d'Échap des vues d'Équipe, `VFGitTiroir.ouvrirSur`) ; Phase 75 (canal de marquage qui rebranche « Voir sur la carte », P74-D-47). Ordre du jalon : après la 79. Recoupements : Phase 75 (mise en évidence continue sur la carte Code : la 74 n'en pose qu'une ponctuelle) ; Phase 77 et Phase 52 (le coût réutilise le calcul de jetons de l'index de la 79, un seul calcul).
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 1, 2, 3) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2, `REGISTRE.md` (AUDC-I04, I05, I06, I07, I08, I21, I28, M4, D8, D9), `DESIGNS.md` § 4 et § 5.
**Un ajout, un retrait :** retirés la boîte de transcript du panneau et son bouton « Lire le transcript » (remplacés par la fiche plein cadre), la durée unique qui compte les veilles (remplacée par la durée par segments) ; la carte « Terminés depuis moins de 24 h » du canevas si elle existe encore (la frise en porte l'historique) ; le lecteur de repli de la régie et l'export `transcript` (74-10, P73-C2).

**Success Criteria** (what must be TRUE):

1. Dans l'onglet Équipe, la bascule « Frise » montre toutes les sessions et tous les agents du lab des dernières 1 h 30, 6 h ou 24 h sur une horloge commune, l'enfant sous son parent, et un worker qui lance des tests pendant dix minutes reste une barre continue ; aucune voie n'a une couleur propre à son nœud.
2. Un agent qui a attendu une réponse de l'humain montre une barre hachurée sur la durée de l'attente, et le temps perdu à attendre se lit, en durée, sur sa fiche et en tête de frise.
3. En déplaçant le curseur au clavier, l'encart « À cet instant » dit quels nœuds du plan étaient portés par un agent au travail et quels fichiers venaient d'être écrits ; « Voir sur la carte » ouvre l'onglet Code avec ces fichiers mis en évidence.
4. La fiche d'un agent s'ouvre en plein cadre depuis la frise et depuis la régie, dit son rattachement (parent, nœud, phase, chacun cliquable), ses durées par segments, ses jetons et ses erreurs, et son fil daté se filtre et suit le direct ; aucune sortie d'outil ni argument de commande n'y apparaît, et rien de la fiche n'est exporté.
5. Les jetons d'une mission égalent la somme de ceux de ses agents, comptés une fois par message, et chaque total dit sa fenêtre ; les agents sans mission sont comptés à part.
6. Les suites du cockpit restent vertes, la chaîne XSS couvre les données de frise et de fiche, et chaque comportement neuf a un témoin qui rougit sans le code.
**Plans:** 10 plans

Plans:

- [x] 74-01-PLAN.md — Modèle pur de la frise, de la relecture et du coût (vague 1)
- [x] 74-02-PLAN.md — Fil réduit : échec d'outil apparié (vague 1, après 79-13)
- [x] 74-03-PLAN.md — Fil de la fiche, markdown fermé et fusion des événements (vague 2)
- [x] 74-04-PLAN.md — Frise : vue de la régie, voies, segments, axe, direct (vague 3)
- [x] 74-05-PLAN.md — Fiche d'agent plein cadre, ouverture depuis la régie, Échap (vague 3)
- [ ] 74-06-PLAN.md — Curseur, encart « À cet instant », « Voir sur la carte » (vague 4)
- [x] 74-07-PLAN.md — Bandeau Dépôt, commit dans le tiroir Git, coût (vague 4)
- [ ] 74-08-PLAN.md — Retraits et gardes d'absence, annulation des trois déclencheurs (vague 4)
- [ ] 74-10-PLAN.md — Retrait du lecteur de repli de la régie (P73-C2) (vague 5)
- [ ] 74-09-PLAN.md — Bornes, chaîne XSS, contrat, VENDORED, documentation et compteur (vague 6)

### Phase 75: L'activité posée sur le code — hotspots, couplage, gardes, empreinte

> **Cadrée le 2026-11-11** (`75-CONTEXT.md`, P75-D-01..31, décisions déléguées, option recommandée, sauf P75-D-28 et P75-D-29 (arbitrages Samuel, AskUserQuestion session principale, 2026-11-11) ; questions au format C76-Q1, P75-Q-06 en attente, bloque 75-10). Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

**Goal:** La carte Code se colore par l'activité : fréquence de changement croisée avec la taille, fichiers qui changent ensemble, fichiers couverts par un gate ou une suite et zones sans témoin, fichiers lus ou modifiés par la mission en cours.
**Requirements**: ACTV-01, ACTV-02, ACTV-03, ACTV-04, ACTV-05, ACTV-06, ACTV-07, ACTV-08, ACTV-09, ACTV-10, ACTV-11, ACTV-12
**Depends on:** Phase 67 (onglet Code) ; Phase 69 (empreinte des agents) ; Phase 79 (contrats C0 à C6 figés le 2026-11-11, amendés A1-A28 : route de frise et champ `cibles` en mémoire, magasin `VF_ETAT`, coquille et graphe servi, retrait de l'appareil de patchs en vague 1) ; Phase 74 (canal de marquage partagé avec la relecture AUDC-I06, P75-D-05) ; ordre du jalon : après la 74. Partage la carte Code avec la Phase 80 (elle la rend navigable, la 75 la marque).
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 5, 6, 7, 8) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2 (AUDC-I12, I13, I36).
**Retrait (un ajout, un retrait) :** la couche déclarative « Travail récent » et `scripts/recent.mjs` du moteur ; l'entrée du menu « ⋯ » reste au même endroit et devient le sélecteur de lentilles (P75-D-28, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11).

**Success Criteria** (what must be TRUE):
  1. Dans l'onglet Code, une lentille choisie dans le menu (Points chauds, Couplage, Gardes, Empreinte) marque chaque carte d'un glyphe à paliers et d'un mot, lisibles sans couleur, sans fond teinté ni couleur d'alerte, et sans déplacer aucune carte.
  2. Les points chauds et le couplage viennent de `git log` local sur 90 jours plafonnés, recalculés seulement quand HEAD ou les refs changent, sans lecture réseau ni écriture dans le lab ; sans git, la carte est identique.
  3. Les fichiers qu'aucune suite ni aucun gate ne nomme se lisent « aucune suite ne le nomme » sur un lab VibeFlow ; ailleurs la lentille se dit absente.
  4. Les fichiers lus ou écrits par les agents des dernières 24 h s'allument avec le nom de l'agent ; un même fichier visé par deux agents, deux branches ou deux plans d'une même vague est signalé avant la fusion, y compris dans les worktrees prouvés du dépôt hors du dossier du lab (P75-D-29).
  5. Les fichiers que les plans non faits vont créer apparaissent en cartes « prévues ».
  6. La couche « Travail récent » et `scripts/recent.mjs` sont retirés ; toutes les suites du cockpit sont vertes sous macOS et Linux, chaîne XSS étendue aux chemins et noms hostiles.
**Plans:** 12 plans en 9 vagues (planifiés le 2026-11-11, corrigés après vérification ; exécution après la Phase 79 entière, la 80 et la 74)

Plans:

- [x] 75-01-PLAN.md — Calcul git : points chauds, couplage, collisions entre branches (v1)
- [x] 75-02-PLAN.md — Gardes : règle de citation de la CI lue dans le socle, suite d'équivalence (v1)
- [x] 75-03-PLAN.md — Chemins, empreinte et collisions d'agents et de plans, preuve générative (v1)
- [x] 75-04-PLAN.md — `files_modified` borné jusqu'à l'instantané, avec la vague de la Phase 80 (v1)
- [x] 75-05-PLAN.md — Route `/api/vf/activite`, schéma `cockpit-activite@1`, témoin d'export (v2)
- [x] 75-06-PLAN.md — Cartes « prévues » : annotateur, règle de rattachement extraite, export sans les prévues (v3)
- [x] 75-07-PLAN.md — Canal de marquage, pied réservé, glyphes, nom accessible, rendu des prévues (v4)
- [x] 75-08-PLAN.md — Sélecteur de lentilles, menu, panneau, compte du radar (v5)
- [x] 75-09a-PLAN.md — Retrait côté assemblage et moteur : `recent-work.json`, `recent.mjs`, étape de `refresh.mjs`, sonde Y reportée (v6)
- [x] 75-09b-PLAN.md — Retrait côté page et jetons : `25-recent.js`, `#btn-recent`, survol, suites `ecrans-recent` et `responsive` adaptées (v7)
- [x] 75-09c-PLAN.md — Retrait : dictionnaires, `moteur-carte`, `chrome-moteur-carte`, `chrome-fr`, grep d'inventaire à zéro (v8)
- [x] 75-10-PLAN.md — Chaîne XSS étendue, sans git, DESIGN.md, CHANGELOG, compteur de suites (v9)

### Phase 76: Traçabilité au cockpit — exigences, décisions, mémoire

> **Cadrée et planifiée le 2026-11-11** (mission de cadrage, `76-CONTEXT.md`, P76-D-01..38 ; P76-D-32 à P76-D-34 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — marque neutre pour les trous, panneaux reliés, format des questions en attente posé maintenant ; les autres : décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée). Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03). Forme : panneaux reliés de l'onglet Projet, sans canevas ni quatrième onglet ; route `GET /api/vf/tracabilite` ; questions en attente lues pour la régie de la Phase 73 ; retrait : le nœud « Exigences » et les liens « couvre » du graphe Projet.

**Goal:** Le cockpit relie exigence → plan → SUMMARY → VERIFICATION → recette avec les trous en rouge, les décisions (ADR, arbitrages préfixés, commits qui les citent) en graphe navigable, et la mémoire des agents en graphe de liens avec ses entrées orphelines ou périmées.
**Requirements**: TRAC-01, TRAC-02, TRAC-03, TRAC-04, TRAC-05, TRAC-06, TRAC-07, TRAC-08, TRAC-09, TRAC-10, TRAC-11, TRAC-12, TRAC-13
**Depends on:** Phase 69 (rattachement des missions) ; ordre du jalon : après la 75. Exécution : après la Phase 79 (première vague et plans 79-05, 79-09, 79-16, 79-17 ; contrats C0, A10 à A13, A30 à A32, A34, A44, A47, A48, A51, A52, A54), et après la Phase 80 pour les plans de page (P80-C76-1 à 5) ; les plans repassent devant un vérificateur frais contre la base qui porte la 79 et la 80 avant exécution.

**Success Criteria** (what must be TRUE):
  1. Le panneau d'une phase montre, pour chaque exigence rattachée, ses quatre maillons lus (plan, SUMMARY, VERIFICATION, recette) avec leur niveau et le premier trou en mot ; les contradictions du ledger se voient, en glyphe et mot, sans couleur d'alerte ni fond teinté.
  2. La vue d'ensemble de Projet donne une ligne par phase du jalon avec ses trous, la liste des ADR et des décisions de phase avec les commits qui les citent, et la mémoire des agents par agent avec ses liens cassés, ses entrées hors index et ses chemins disparus ; chaque objet s'ouvre d'un geste et le Retour commun ramène au précédent.
  3. Les preuves de vérification déjà écrites (VERIFICATION, recette, traces rouges, critères des plans) sont attachées à la phase et à ses plans, en liens vers leurs fichiers.
  4. Rien de la mémoire des agents au-delà de sa structure n'entre dans la page ; aucune donnée de la phase n'entre dans l'export ; un lab sans ADR, sans mémoire, sans compartiment ou sans git voit une ligne neutre et rien ne casse.
  5. Les questions en attente écrites au format C76-Q1 dans les registres de phase sont lues et servies à la régie de la Phase 73 ; une entrée mal formée n'est jamais rendue « en attente ».
  6. Le nœud « Exigences » quitte le graphe Projet après que la porte de la Phase 80 et le panneau d'exigence ont été rebranchés ; toutes les suites du cockpit sont vertes sous macOS et Linux.
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 10, 11, 14) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2.
**Plans:** 9 plans

Plans:

- [x] 76-01-PLAN.md — Chaîne d'exigences : maillons, contradictions, preuves, bilans, Jalon (fonctions pures) (v1)
- [x] 76-02-PLAN.md — Décisions : extracteur `vf-cockpit-registres.mjs` et passage git des commits citants (v1)
- [x] 76-03-PLAN.md — Mémoire des agents : entrées, liens, états (v2)
- [x] 76-04-PLAN.md — Branchement dans la collecte (champs facultatifs de `cockpit-project@1`) (v2)
- [x] 76-05-PLAN.md — Route `GET /api/vf/tracabilite` (v3)
- [x] 76-06-PLAN.md — Page : section de phase, preuves, Jalon, panneau d'exigence (v4)
- [x] 76-07-PLAN.md — Page : Décisions, Mémoire, panneaux d'ADR, de décision, d'entrée, commits (v5)
- [x] 76-08-PLAN.md — Retrait du nœud `.req`, puis clôture (v6)
- [x] 76-09-PLAN.md — Questions en attente : lecture des sections « À Samuel » et champ `meta.vf.questions` (v4)

### Phase 77: Santé de la méthode et synthèse — jauges, dernière visite, burn-up

> **Cadrée et planifiée le 2026-11-11** (mission de cadrage parallèle, `77-CONTEXT.md`, P77-D-01..36 : décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée). Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03). Deux questions non bloquantes à Samuel (A77-1, A77-2).

**Goal:** Le cockpit montre en jauges les budgets de la méthode (densité des agents, skills, taille du ROADMAP et du BACKLOG, baseline d'instructions), résume ce qui a changé depuis la dernière visite, et trace le burn-up du jalon en pourcentage strict.
**Requirements**: SYNT-01, SYNT-02, SYNT-03, SYNT-04, SYNT-05, SYNT-06, SYNT-07, SYNT-08, SYNT-09, SYNT-10
**Depends on:** Phase 69 (avancement des phases et du jalon) ; Phase 79, revalidée à `673c879d`, plan par plan : 79-05 (table `ROUTES`, réponse gardée), 79-07 (lanceur, `envGit`), 79-02 et 79-06 (lancement des suites depuis le module), 79-01 et 79-11 (inventaire `AJOUT`, cliquet de colonnes), 79-09 (instantané), 79-12 (route d'état), 79-16 (coquille, `surOnglet`, liste `/_vf/`), 79-17 (`VF_ETAT`) avant les plans du cockpit concernés ; 79-13 (frise) pour le seul coût par phase et par étage ; Phase 74 (74-01, agrégat de coût partagé) ; ordre du jalon : après la 76. Le plan des gates (`plugin/conductor`, 77-01) ne dépend d'aucune phase.
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 12, 15, 16) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2, registre AUDC-I08 et AUDC-I14 ; contrats de la Phase 79 (`79-CONTEXT.md`, commits `3119d82a` et `2ae6607a` de `feat/phase-79-socle-cockpit`).
**Retrait (un ajout, un retrait):** la prose recopiée du STATE sous « Maintenant » (`lastDesc`), remplacée par la synthèse datée (P77-D-12).

**Success Criteria** (what must be TRUE):
  1. Sur Projet, un bouton « Synthèse » ouvre dans le panneau en place « Depuis votre dernière visite », le burn-up et la santé de la méthode, sans 4ᵉ onglet, sans couleur d'alerte ni fond teinté, sans pousser la carte, et sans modifier `ui/00-vibeflow.js` ni `ui/20-health.js`.
  2. Chaque jauge reprend la valeur, le budget et le verdict que produit le gate (`--format=tsv` en lecture seule de `check-method-budget.sh` et `check-instruction-budget.sh`), appelé à la demande hors de la collecte, sans réseau ni écriture dans `.planning/` ; « non applicable » ou « indisponible », jamais 0, quand le gate ne mesure pas.
  3. « Depuis votre dernière visite » montre les phases avancées, les commits arrivés, les sessions finies (avec la réserve des 24 h) et les blocages nouveaux ou levés, à partir d'un repère par lab gardé dans le navigateur, sur liste fermée, qui n'avance qu'après 30 min d'absence ou sur « Tout vu ».
  4. Le burn-up trace les clôtures et le périmètre datés par la checklist du ROADMAP, avec « N sur M · P % » du pied de jalon ; une phase close sans date est nommée, jamais estimée.
  5. Le coût par phase et par étage sur les dernières 24 h (jetons et durée, sans monnaie) se lit dans la synthèse une fois la route de frise de la Phase 79 livrée ; une voie non rattachée est dite comme telle.
  6. Chaque comportement a un témoin montré rouge par une mutation puis vert ; toutes les suites du cockpit et du conductor sont vertes sous macOS et Linux.
**Plans:** 0/8 plans executed (8 plans en 6 vagues, planifiés le 2026-11-11, revalidés le 2026-11-11)

Plans:

- [x] 77-01-PLAN.md — gates, `--format=tsv` dans `check-method-budget.sh` et `check-instruction-budget.sh`, lecture seule, texte identique octet pour octet (v1)
- [x] 77-02-PLAN.md — données du planning de la collecte, dates du burn-up et blocages du STATE, retrait de `lastDesc` (v1)
- [x] 77-03-PLAN.md — route `GET /api/vf/methode`, lancement asynchrone borné, cache de 60 s, un seul appel en cours (v2)
- [x] 77-04-PLAN.md — modules purs du calcul « depuis votre dernière visite » et de la mémoire de visite (v2)
- [x] 77-05-PLAN.md — coquille de la Synthèse (bouton, panneau, registre des blocs, ligne-résumé) et banc navigateur commun (v3)
- [x] 77-06-PLAN.md — blocs burn-up du jalon et santé de la méthode (v4)
- [x] 77-08-PLAN.md — bloc « Depuis votre dernière visite », feuille neutre, README et CHANGELOG du module (v5)
- [x] 77-07-PLAN.md — coût par phase et par étage sur les dernières 24 h (v6, à revalider après les Phases 79 et 74)

### Phase 78: Git dans le cockpit — en-tête, graphe des worktrees et branches, données Git
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 78 (corps) -->
**État :** complete 2026-11-06 — PR #216, GITC-01..14 cochées, publiée en `v2.76.0` ; corps dans l'archive ci-dessus.

### Phase 79: Socle du cockpit — une collecte, un flux, une route d'état

> **Cadrée et planifiée le 2026-11-11** par le manager de la phase (décisions déléguées par Samuel, message session principale, 2026-11-08, option recommandée ; arbitrages AUDC-Q2, Q4, Q5 du 2026-11-11 en vigueur). Contrats fournis aux Phases 73, 74, 75, 76, 77 et 80 : `79-CONTEXT.md` § « Contrats fournis » et amendements A1 à A55, décisions P79-D-01 à P79-D-33 (P79-D-33 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-11). Questions à Samuel, non bloquantes : S-1 à S-4.

**Goal:** Le serveur du cockpit collecte sans bloquer et sert un état unique : un index incrémental des transcripts, une route d'état en JSON lue par la page et par `vf-signal`, un seul flux d'événements partagé entre les onglets, des données sorties de la page, et un serveur lancé depuis le module plutôt que depuis une copie dans le lab.
**Requirements**: SOCL-01, SOCL-02, SOCL-03, SOCL-04, SOCL-05, SOCL-06, SOCL-07, SOCL-08, SOCL-09, SOCL-10, SOCL-11, SOCL-12, SOCL-13, SOCL-14, SOCL-15, SOCL-16, SOCL-17, SOCL-18, SOCL-19, SOCL-20, SOCL-21, SOCL-22, SOCL-23, SOCL-24, SOCL-25, SOCL-26, SOCL-27
**Depends on:** Phase 67 (serveur unique) ; Phase 69 (collecteur `who`) ; lot zéro de l'audit (livré dans la base `integration/cockpit-audit`). Les Phases 74, 75 et 77 en dépendent (contrats C1 à C3) ; la 73, la 76 et la 80 consomment C2, C4, C5 et la règle de routes A10-A11 et placent leurs plans après la première vague de la 79.
**Sources:** `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2 ; registre `AUDC-D5`, `D9`, `H1`, `H2`, `H3`, `H4`, `H5`, `AM1` à `AM7`, `AB1`, `A-02` (classe restante), `A-03`, `A-04` (limites), `D-M2`, `D-M13`, `D-M15`, `M7`, `I18` à `I20`, `I22`, `I31`, `I32`, `I37`.
**Un ajout, un retrait:** ajoute l'index, les routes d'état, de frise et de graphe, le flux partagé, la coquille statique, le worker de mise en page ; retire la copie renommée du code dans chaque lab, l'appareil de patchs du moteur, la page Équipe reconstruite à chaque requête, la réécriture de `project.html` à chaque changement, la collecte refaite par `vf-signal` quand le serveur tourne, l'observateur global de traduction et les observateurs de réparation.
**Success Criteria** (what must be TRUE):
  1. Aucun code ni contrat n'est lu ou évalué depuis la sortie du cockpit dans le lab : un code planté dans la sortie ne s'exécute jamais, ni côté serveur ni côté page ; la classe des chemins jugés sur leur forme écrite est fermée par une preuve générative.
  2. Pendant une collecte et un remplissage d'index, une requête au serveur répond en moins de 50 ms au 99ᵉ centile (témoin rouge sur la base : pics de 416 à 470 ms).
  3. `GET /api/vf/state`, `GET /api/vf/frise` et `GET /api/vf/graphe` servent les contrats C2, C3 et C5 sous les contrôles de C0 ; `vf-signal` ne refait plus sa collecte quand un serveur du lab tourne.
  4. Sept onglets ouverts sur le même lab ne tiennent qu'un flux d'événements ; fermer l'onglet élu ne recharge aucune page ; un flux muet est déclaré coupé en 45 s.
  5. Un agent clos reste rattaché à son nœud après le relâchement du verrou (registre archivé 24 h, nœud écrit dans le mandat).
  6. Ni l'index, ni l'état, ni la frise, ni les cibles, ni les verrous n'entrent dans l'export ; aucun chemin absolu ni identifiant de session n'est émis hors des routes à la demande existantes.
**Plans:** 22 plans en 11 vagues

Plans:

- [x] 79-01-PLAN.md — Fork assumé : retrait de l'appareil de patchs du moteur (vague 1)
- [x] 79-02-PLAN.md — Aide commune de lancement du serveur dans les suites, migration (vague 1)
- [x] 79-03-PLAN.md — Registre du verrou archivé 24 h, verbe registry, plan de mission publié (vague 1, conductor)
- [x] 79-04-PLAN.md — Nœud écrit dans chaque mandat, doctrine de publication (vague 2, références)
- [x] 79-05-PLAN.md — Table des routes, réponse gardée, annotateurs du graphe Code (vague 1)
- [x] 79-06-PLAN.md — Serveur lancé depuis le module, sortie = données, empreinte, orphelin, mesure du confinement (vague 2)
- [x] 79-07-PLAN.md — Résolution physique des chemins, cible interne protégée, pilotes git (vague 2)
- [x] 79-08-PLAN.md — Index incrémental des transcripts et contrat de forme étendu (vague 2)
- [x] 79-09-PLAN.md — Collecte hors de la boucle, registre lu, verrous projetés (vague 3)
- [x] 79-10-PLAN.md — Traduction au point d'émission (vague 3)
- [x] 79-11-PLAN.md — Plafond en colonnes et code navigateur rangé (vague 4)
- [x] 79-12-PLAN.md — Route d'état et vf-signal par la route (vague 4)
- [x] 79-13-PLAN.md — Route de frise et cibles en mémoire (vague 5)
- [x] 79-14-PLAN.md — Flux partagé entre onglets et veille de silence (vague 5)
- [x] 79-15-PLAN.md — Route graphe, fin de la réécriture de project.html, témoin d'export (vague 6)
- [x] 79-16-PLAN.md — Coquille statique servie du module (vague 7)
- [x] 79-17-PLAN.md — Magasin d'état côté page (vague 8)
- [x] 79-18-PLAN.md — Mise en page dans un worker (vague 9)
- [x] 79-19-PLAN.md — Journal des attentes : S0 OUI, sans code (vague 10)
- [x] 79-20-PLAN.md — Documentation et version du module (vague 11)
- [x] 79-21-PLAN.md — Coût borné de la correspondance de motifs du moteur (vague 3)
- [x] 79-22-PLAN.md — Transcript et détail par la table en mémoire de la collecte (vague 8)

### Phase 80: Trois onglets, trois formes — Projet en couloirs, clavier, navigation

> **Cadrée le 2026-11-11** par le manager de la mission (`80-CONTEXT.md`, P80-D-01 à P80-D-60, décisions déléguées par Samuel, message session principale, 2026-11-08, option recommandée ; cinq réouvertures rangées « À Samuel », S80-1 à S80-5). Inscrite le 2026-11-11 depuis l'audit du cockpit du 2026-11-10 (demande de Samuel, session principale Claude Code, 2026-11-10).

**Goal:** L'onglet Projet se lit d'un regard à toute largeur (les phases rangées par état, le graphe à la demande), chaque carte du canevas est atteignable au clavier et nommée pour un lecteur d'écran, et l'on ne se perd plus sur la carte du code : un ajustement qui montre tout, une minicarte, une palette de commandes, des surcouches qui retiennent le focus.
**Requirements**: FORM-01, FORM-02, FORM-03, FORM-04, FORM-05, FORM-06, FORM-07, FORM-08, FORM-09, FORM-10, FORM-11, FORM-12, FORM-13, FORM-14, FORM-15, FORM-16, FORM-17, FORM-18
**Depends on:** Phase 71.5 (jetons de couleur et d'espacement) ; Phase 78 (en-tête). Vagues 1 et 2 sans dépendance à la Phase 79 ; le lot moteur (`viewer.html`), les jetons et les onglets sans rechargement après la fusion de la Phase 79 (contrats C5, C6 et amendement A1 à A7 de `79-CONTEXT.md`, commits `3119d82a` et `2ae6607a` de `feat/phase-79-socle-cockpit`). Fournit à la Phase 76 les contrats P80-C76-1 à 4 (panneau de Projet) et aux Phases 73 et 74 la pile de surcouches.
**Sources:** `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2 ; `2026-11-10-audit-cockpit/DESIGNS.md` § 6 et § 7 ; registre `AUDC-BL1`, `BL2`, `M1`, `M2`, `M5`, `M6`, `M8`, `M10`, `M12`, `X1` à `X3`, `X5`, `X7`, `X8`, `F1`, `F3` à `F5`, `F7`, `I23` à `I27`, `I29`, `I30` (X4, X6, M7, M11 et les parts lot 0 de M10 et X7 sont livrés).
**Retraits:** le canevas comme vue par défaut de Projet ; les vignettes Backlog, Graines et Releases ; les copies de la formule de cadrage ; les listes « surcouche ouverte » recopiées.
**Success Criteria** (what must be TRUE):
  1. À 1440, 1024 et 390 px, la racine de Projet montre les phases en quatre couloirs par état, titres lisibles sans zoom ; le graphe s'ouvre par une bascule ; au téléphone, une liste triable.
  2. Au clavier seul, on atteint, parcourt et ouvre toute carte du canevas, et chaque surcouche retient le focus puis se ferme à Échap en rendant le focus à son ouvreur.
  3. Sur Code, la minicarte et les repères de bord mènent à toute carte hors champ sans descendre sous le plancher de lisibilité ; `+` et `-` gardent la carte sélectionnée en place ; la palette atteint vues, actions et onglets.
  4. Le tiroir Git est lisible à 1024 × 768 sans pousser la carte ; les jetons repris passent les seuils de contraste mesurés dans les deux thèmes.
  5. Après la Phase 79, changer d'onglet ne recharge plus la page et garde tiroirs, zoom et historique du terminal.
  6. Toutes les suites du cockpit vertes sous macOS et Linux ; chaque comportement porte un témoin rouge sur la base puis vert.
**Plans:** 21 plans en 11 vagues (vagues 1 à 3 sans dépendance à la Phase 79 ; à partir de 80-09 : 79-01 à 79-18 fusionnés ; 80-18 après 79-20 ; P80-Q-01 à P80-Q-05 tranchées, FORM-18 portée par 80-14, 80-15, 80-19 et 80-20)

Plans:

- [x] 80-01-PLAN.md — Clavier du canevas (un arrêt de tabulation, voisin spatial, anneau sur la carte) (v1)
- [x] 80-02-PLAN.md — Pile de surcouches, panneau fermé hors tabulation, retrait des trois listes (v1)
- [x] 80-03-PLAN.md — Données de Projet (avancement, exigences, vague, recette ; DIFFÉRÉ retiré du pied) (v1)
- [x] 80-04-PLAN.md — Projet en couloirs, ?vue=, naviguer(), visite, contrats C76-1/2/3 (v2)
- [x] 80-05-PLAN.md — Coin bas-droit : minicarte, repères, ligne d'état, zone basse du téléphone (v2)
- [x] 80-06-PLAN.md — Tiroir Git : pagination, worktrees repliés, volet bas, poignée de largeur, ouvrirSur(sha) (v2)
- [x] 80-07-PLAN.md — Forme Liste, intérieur de phase, touche v, mémoire par lab (v3)
- [x] 80-08-PLAN.md — Pile Retour du panneau VF_PANNEAU (C76-3, C76-5) (v3)
- [x] 80-09-PLAN.md — Lot moteur A1 : cadrage unique, champ de lecture, zoom réversible, garde de saisie (v4)
- [x] 80-10-PLAN.md — Onglets sans rechargement, « Réessayer », VF_ONGLETS.aller (v5)
- [x] 80-11-PLAN.md — Lot moteur A2 : vocabulaire du panneau de Projet (v5)
- [x] 80-12-PLAN.md — Cadrer la sélection et ses voisins (touche C) (v5)
- [x] 80-13-PLAN.md — Lot moteur A3 : lien de vue (z=, git=1), mémoire des tiroirs (v6)
- [x] 80-14-PLAN.md — Lot moteur B : palette, registre des raccourcis, ARIA, copier le lien, ligne du terminal (P80-D-55) (v7)
- [x] 80-15-PLAN.md — Aide ?, ligne du terminal (P80-D-55) (v8)
- [x] 80-16-PLAN.md — Jetons X5, DESIGN.md, découpe de 00-vibeflow.js (v8)
- [x] 80-19-PLAN.md — Santé en français (P80-Q-03, P80-D-54) (v8)
- [x] 80-21-PLAN.md — Échec d'un changement d'onglet : Lecture impossible, Réessayer (v8)
- [x] 80-17-PLAN.md — Finitions F1, F3, F4, F5 (après 80-16 : colonnes-baseline.txt partagé) (v9)
- [x] 80-20-PLAN.md — Titre de vue, en-tête en trois groupes, chevron, icônes, ouvreur Git 36/44 (P80-Q-01, P80-Q-02, P80-Q-05) (v10)
- [x] 80-18-PLAN.md — Assemblage : compteur des README, table du partage CI, CHANGELOG, non-régression (v11)

### Phase 81: Agir sur une session depuis le cockpit
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — Phase 81 (corps ; à réinsérer au cadrage de la phase) -->
**État :** non cadrée, reportée (`AUDC-Q3` tranchée « plus tard » par Samuel le 2026-11-11), aucun plan ; corps (but, sources, dépendances) dans l'archive ci-dessus, à réinsérer au cadrage.


<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md — tri du ROADMAP du 2026-11-11 (jointure des cadrages) -->
**Tri du 2026-11-11 (jointure des cadrages) :** « Tout sauf l'en-cours (Recommandé) » (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11). Fiche de la Phase 41, corps des Phases 57 à 66 et 81, des phases closes du cockpit (67 à 72, 71.5, 78), introductions des jalons equipe-produit-v1.0 et vibeflow-v2.0, entrées de la liste « Milestones », lignes longues de la checklist et de la table `## Progress`, listes de plans des Phases 75, 76, 77 et 80 : texte intégral octet pour octet dans `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11-jointure.md` (blob d'origine `de4f6ffeff7c37c21d0b471fef266bf83af3934a`) ; en-têtes `### Phase` tous conservés.
