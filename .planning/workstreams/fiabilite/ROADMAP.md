# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Milestones

- ✅ **vfdo-v1.0** — Module dev-orchestrator (Phase 1) — clôturé 2026-06-04
- ✅ **install-ux-v1.0** — Phases 2-6 — clôturé 2026-06-05 (plugin + skill à toggles + scope) — release `v2.4.0`
- ✅ **dev-doctrine** — Phases 7-8 — doctrine dev (SOLID/DRY/KISS/YAGNI/Clean Archi/Clean Code/TDD) + consolidation des doublons qualité — clôturé 2026-07-07 — release `v2.20.0`
- ✅ **memory-swarm-rnd** — Phase 9 — R&D : transposition du modèle mémoire + patterns swarm de jcode — spike GO, shippé `v2.28.0` (ADR-052 mémoire vivante + ADR-053 swarm)
- ✅ **gsd-migration** — Phases 10-11 — clos 2026-07-26, release `v2.39.0` — migration du package GSD `get-shit-done-cc` → `@opengsd/gsd-core@^1` (VOC-02)
- ✅ **vf-routing** — Phases 12-14 — clos 2026-07-26, release `v2.37.0` — routage fin des intentions (verbes `/vf-*` à l'origine ; carte d'intention agentique depuis la bascule v2.33.0), couverture complète des skills GSD, pont spec → feuille de route, et frontière d'altitude avec le moteur de planning GSD
- ✅ **agentique-v1.0** — Phases 15→29 (18 et 25 reportées) — **clos 2026-08-15**, releases `v2.40.0` → `v2.52.0` (détail : `.planning/milestones/agentique-v1.0-ROADMAP.md` ; texte d'origine : `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md`)
- ✅ **fiabilite-v1.0** — « ce qui survit » — Phases 30-35, 37-41.4 + Phases 18 et 25 héritées — **clos 2026-10-08**, releases `v2.53.0` → `v2.69.0` (plans 41-07 à 41-13 confiés à Willy, hors clôture ; détail : `.planning/milestones/fiabilite-v1.0-ROADMAP.md` ; texte d'origine : `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md`)
- 📋 **equipe-produit-v1.0** — « l'équipe produit : rôles humains, amont produit, état partagé » — Phases
  57-66 — **inscrit 2026-10-08**, prochain jalon exécuté (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08). Germe de `SEED-001` : ses trois déclencheurs
  sont réunis à la clôture de `fiabilite-v1.0`. Spec : `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md`.
- 📋 **ecc-inspiration-v1.0** — « ce qu'on emprunte à ECC » — Phases 51-56 — **inscrit
  2026-09-25** — six emprunts mesurés au dépôt `affaan-m/ECC` (snapshot avant compaction,
  télémétrie d'usage et coût, apprentissage adossé à l'observation, audit du harness comme
  surface d'attaque, installeur et mémoire portables entre runtimes, packs de règles par
  langage). Étude comparative : `.planning/research/2026-09-25-ecc-inspiration-etude.md`. Jalon logé dans ce compartiment, section distincte
  dans la ROADMAP plate **sans `gsd-new-milestone`** (même forme que `gouvernance-labs-v1.0`) ;
  **exécution après la clôture de `fiabilite-v1.0`**, en parallèle du jalon de Willy
  (compartiment `gouvernance`) — arbitrage Samuel, AskUserQuestion session principale, 2026-09-25.
- 📋 **vibeflow-v2.0** — « le cockpit VibeFlow » — Phases 67-81 — **inscrit 2026-11-01** — le cockpit en tête :
  un cockpit floorplan (onglets Projet et Code) sur un socle partagé, puis `vf-signal` embarqué sur ce même socle, puis
  le suivi du travail en cours dans le cockpit (Phase 69, inscrite 2026-11-03), puis les finitions UI du cockpit (Phase 70, inscrite 2026-11-03), puis le terminal intégré (Phase 71) et
  lancer du travail depuis les cartes (Phase 72), inscrites 2026-11-03, puis les Phases 73 à 77 (gouvernance, équipe dans le
  temps, activité sur le code, traçabilité, santé et synthèse), inscrites 2026-11-03 ; ordre
  69 → 73 → 68 → 70 → 71 → 72 → 74 → 75 → 76 → 77 (arbitrages Samuel, AskUserQuestion session principale, 2026-11-03).
  S'y ajoutent les Phases 79 à 81 (socle, formes, actions sur une session), inscrites 2026-11-11 depuis l'audit du cockpit du 2026-11-10
  (`.planning/research/2026-11-10-audit-cockpit-etude.md` ; demande de Samuel, session principale, 2026-11-10) ; leur place dans l'ordre
  est dite en tête de la section du jalon.
  `equipe-produit-v1.0` reste ouvert, son sort se tranche à sa clôture (arbitrage Samuel, AskUserQuestion session
  principale, 2026-11-01). Sources : `.planning/notes/2026-11-01-cockpit-facettes.md`,
  `docs/research/2026-11-01-etude-floorplan-cockpit.md`, `.planning/spikes/WRAP-UP-SUMMARY.md`. Même forme que ECC : section
  distincte de la ROADMAP plate, **sans `gsd-new-milestone`** (le STATE du compartiment est sur `vibeflow-v2.0` depuis le 2026-11-03).
  Publié au 2026-11-11 : la Phase 67 en `v2.75.0`, les Phases 68 à 72, 71.5 et 78 en `v2.76.0` (2026-11-06) ; les Phases 71.5 et 78,
  inscrites le 2026-11-05, sont décrites dans leur section.

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
- [x] Phase 41: Posture de protection du dépôt (**plans 41-07 à 41-13 confiés à Willy, hors clôture de `fiabilite-v1.0` — arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Les confier à Willy » pour 41-07 à 41-09, étendu à toute la chaîne (« Toute la chaîne à Willy ») ; 41-07 partiellement entamé, lignes `PR-R-*` de `41-PREUVES.md`, 2026-09-24 ; PROT-01 cochée le 2026-09-24 sur la pose des rulesets, complément attendu : la mesure du refus réel d'un push direct (41-09, complément en 41-13) est confiée à Willy** ; inscrite 2026-09-15, arbitrage Samuel AskUserQuestion session principale ; cahier des charges au BACKLOG ; séquencée après la 40 ET la calibration 25-04 ; **cadrée le 2026-09-17** — `41-CONTEXT.md`, arbitrages Samuel AskUserQuestion session principale 2026-09-17 : bypass rôle write, PR obligatoire, 4 checks requis, CODEOWNERS étroit, tags v* protégés ; critère 2 reformulé et méthodes de merge non restreintes, mêmes canal et date — **PÉRIMÈTRE RECADRÉ SANS ADMIN LIVRÉ le 2026-09-18, mergée PR #80, SHIPPÉE v2.64.0** : trois gardes in-repo qui signalent et tracent sans jamais verrouiller (G-1 `check-baseline-arbitrage.sh`, G-2 `check-gate-touche.sh`, G-3 `check-push-sans-pr.sh`) + doctrine ADR-072 ; **critères de succès 1 à 3 du ROADMAP d'origine restent HORS D'ATTEINTE sans accès admin GitHub** (au 2026-09-18 : PROT-01 non coché, `REQUIREMENTS.md` — depuis cochée le 2026-09-24) ; au 2026-09-18 : volet rulesets côté serveur **DIFFÉRÉ au BACKLOG** (rulesets posés depuis le 2026-09-23) avec son déclencheur de reprise — le compte `picmakpro` est celui de Willy, co-mainteneur du dépôt, qui a accepté de poser ce volet (WhatsApp, 2026-09-23) **avant** la clôture de `fiabilite-v1.0`, puisque PROT-01 en fait partie (correction du 2026-09-23 : la formulation précédente inversait la séquence — cf. `BACKLOG.md` § « Protection de `main` côté GitHub »))
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
- [x] Phase 68: Embarquer vf-signal sur le socle partagé (inscrite 2026-11-01, jalon vibeflow-v2.0) — complete 2026-11-04 : 13/13 plans, VFSG-01..13 cochées, PR #199 mergée le 2026-11-04T17:18:25Z (`3c73fc0c`), publiée en `v2.76.0`
- [x] Phase 69: Suivi du travail en cours dans le cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-04
- [x] Phase 70: Finitions UI du cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-04 : 12/12 plans, recette par juges frais jouée et triée par Samuel (`70-RECETTE-JUGES.md`), PR #200 mergée le 2026-11-04T21:02:38Z (`503aa657`), publiée en `v2.76.0` ; au ledger, UIFN-01 à 09 et 11 à 14 cochées (04, 06 et 07 le 2026-11-05, les dix autres le 2026-11-11, alignement demandé par Samuel (session principale Claude Code, 2026-11-11)), UIFN-10 décochée (captures hors dépôt sans empreinte ; REQUIREMENTS.md)
- [x] Phase 71: Terminal intégré au cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-05 : PR #203 (`d4171ded`) et correctif Safari PR #209, recette humaine jouée par Samuel le 2026-11-05 (Arc, Firefox, Safari, clavier AZERTY, `71-RECETTE-HUMAINE.md`), TERM-01..12 cochées, publiée en `v2.76.0`
- [x] Phase 71.5: Réexamen du design system du cockpit — couleurs d'abord, puis icônes, espacements, hiérarchie des vues (INSERTED, inscrite 2026-11-05, élargie le même jour, jalon vibeflow-v2.0) — complete 2026-11-06 : mission design, sans plan GSD ni exigence au ledger, juges de rendu au-dessus de 70/100, PR #213 reprise par merge commit dans la PR de release #217 (`de19669b`), publiée en `v2.76.0`
- [x] Phase 72: Lancer du travail depuis les cartes du cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-06 : 16/16 plans, LANC-01..11 cochées, LANC-12 décochée (recette au vrai `claude` non jouée), PR #214 reprise par merge commit dans la PR de release #217 (`de19669b`), publiée en `v2.76.0`
- [ ] Phase 73: Gouvernance au cockpit — arbitrages en attente, worktrees et verrous (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [ ] Phase 74: L'équipe dans le temps — swim-lanes, coût, replay (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [ ] Phase 75: L'activité posée sur le code — hotspots, couplage, gardes, empreinte (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [ ] Phase 76: Traçabilité au cockpit — exigences, décisions, mémoire (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [ ] Phase 77: Santé de la méthode et synthèse — jauges, dernière visite, burn-up (inscrite 2026-11-03, jalon vibeflow-v2.0)
- [x] Phase 78: Git dans le cockpit — en-tête, graphe des worktrees et branches, données Git (inscrite 2026-11-05, jalon vibeflow-v2.0) — complete 2026-11-06 : 11/11 plans, GITC-01..14 cochées, PR #216 reprise par merge commit dans la PR de release #217 (`de19669b`), publiée en `v2.76.0`
- [ ] Phase 79: Socle du cockpit — une collecte, un flux, une route d'état (inscrite 2026-11-11, jalon vibeflow-v2.0)
- [ ] Phase 80: Trois onglets, trois formes — Projet en couloirs, clavier, navigation (inscrite 2026-11-11, jalon vibeflow-v2.0)
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
| 41. Posture de protection du dépôt | fiabilite-v1.0 | 12/19 | Complete hors 41-07 à 41-13, confiés à Willy — PR #80, release `v2.64.0` ; rulesets posés par Willy le 2026-09-23 | 2026-09-22 |
| 57. Verrou de driver par compartiment | equipe-produit-v1.0 | 16/16 | Complete — PR #152 (merge `--admin`, 2026-10-16), release `v2.70.0` | 2026-10-12 |
| 58. Rôles de poste — installeur, profils solo / product / dev | equipe-produit-v1.0 | 12/12 | Complete (2 overrides, Samuel 2026-10-22) — release `v2.71.0` | 2026-10-22 |
| 59. Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate | equipe-produit-v1.0 | 8/8 | Complete — porte de phase verte, PRDT-01..12 cochées, livrée en `v2.73.0` | 2026-10-27 |
| 60. Gate architecture avant découpage et validation des phases proposées | equipe-produit-v1.0 | 9/9 | Complete — porte de phase verte, ARCG-02..08, 10, 11 cochées, ARCG-01 et ARCG-09 partielles (dettes nommées), livrée en `v2.74.0` | 2026-10-29 |
| 61. Collaboration à deux humains — divergence armée, preuve sur lab réel | equipe-produit-v1.0 | 8/8 | Complete — porte de phase verte, COLB-01..07 cochées, COLB-09 partielle (dette nommée), COLB-08 décochée (preuve humaine attendue), livrée en `v2.74.0` | 2026-10-29 |
| 62. Décision sur l'approche plateforme, sur preuve | equipe-produit-v1.0 | 1/1 | Complete — décision A (approche C différée), réexamen 2027-01-31, PLTF-01..02 cochées, sans release (ADR-073) | 2026-10-29 |
| 67. Cockpit floorplan sur socle partagé | vibeflow-v2.0 | 7/7 | Complete — PR #187, CKPT-01..12 cochées, release `v2.75.0` | 2026-11-03 |
| 68. Embarquer vf-signal sur le socle partagé | vibeflow-v2.0 | 13/13 | Complete — PR #199, VFSG-01..13 cochées, étapes 4 et 5 de la recette reportées (P68-D-35), release `v2.76.0` | 2026-11-04 |
| 69. Suivi du travail en cours dans le cockpit | vibeflow-v2.0 | 9/9 | Complete — PR #198, vérification 16/16, CKPT-13..28 cochées, release `v2.76.0` | 2026-11-04 |
| 70. Finitions UI du cockpit | vibeflow-v2.0 | 12/12 | Complete — PR #200, recette par juges triée par Samuel, UIFN-01 à 09 et 11 à 14 cochées, UIFN-10 décochée, release `v2.76.0` | 2026-11-04 |
| 71. Terminal intégré au cockpit | vibeflow-v2.0 | 11/11 | Complete — PR #203 et #209, recette humaine du 2026-11-05, TERM-01..12 cochées, release `v2.76.0` | 2026-11-05 |
| 71.5. Réexamen du design system du cockpit | vibeflow-v2.0 | mission design, sans plan GSD | Complete — PR #213, juges de rendu au-dessus de 70/100, aucune exigence au ledger, release `v2.76.0` | 2026-11-06 |
| 72. Lancer du travail depuis les cartes du cockpit | vibeflow-v2.0 | 16/16 | Complete — PR #214, LANC-01..11 cochées, LANC-12 décochée (recette au vrai `claude` non jouée), release `v2.76.0` | 2026-11-06 |
| 78. Git dans le cockpit | vibeflow-v2.0 | 11/11 | Complete — PR #216, GITC-01..14 cochées, release `v2.76.0` | 2026-11-06 |

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ agentique-v1.0 — Durcissement du moteur d'équipes agentique (Phases 15→29, 18 et 25 reportées) — SHIPPED 2026-08-15 -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-10-13.md — ✅ fiabilite-v1.0 — « ce qui survit » (Phases 30-35, 37-41.4 + 18 et 25 héritées) — SHIPPED 2026-10-08, releases `v2.53.0` → `v2.69.0` -->

## Phase 41 — chaîne de mesures confiée à Willy (hors clôture de fiabilite-v1.0)

> Jalon clos le 2026-10-08. Cette fiche reste dépliée parce que les plans 41-07 à 41-13 continuent
> côté Willy (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02).

### Phase 41: Posture de protection du dépôt

> **Origine** : finding de l'audit de mission de la Phase 25 (vague 3, 2026-09-15) —
> `gh api repos/picmakpro/vibeflow-os/rulesets` rend `[]` : `main` n'est protégée par rien, donc
> **tout gate in-repo est neutralisable depuis la PR qu'il juge** (une même PR peut modifier un
> gate, sa suite de tests et l'étape CI qui l'invoque). Risque structurel et antérieur à la 25,
> nommé par aucun threat ID de son registre STRIDE. Décision Samuel (AskUserQuestion session
> principale, 2026-09-15) : **ouvrir une phase dédiée** plutôt que poser un ruleset au passage
> d'une mission — changer les règles du merge pendant qu'une PR est ouverte modifierait les
> conditions de cette PR en cours de route. Cahier des charges : `BACKLOG.md` § « Posture de
> protection de `main` — TRANCHÉ : phase dédiée à inscrire (2026-09-15) ».

**Goal**: La branche `main` est protégée par une règle machine — CI verte requise avant merge —
sans casser le flux de release existant (bump → merge → tag annoté → release GitHub) ni les
hotfix urgents.
**Depends on**: aucune dépendance de code. Séquencée **après la Phase 40 et la calibration 25-04** :
les deux PR en attente ne doivent pas changer de règles de merge en vol — même raison qui a fait
différer cette inscription après le merge de la PR #67.
**Requirements**: PROT-01, PROT-02, PROT-03, PROT-04 (cadrage du 2026-09-17, `41-CONTEXT.md`) —
PROT-01 (rulesets de branche et de tags posés et prouvés), PROT-02 (compatibilité avec la
discipline de release du `CLAUDE.md` — `check-release-tag` `main`-only, tag et release GitHub
post-merge, hook `pre-push` conservé), PROT-03 (politique hotfix et de contournement écrite,
ADR-072), PROT-04 (O-3 « gardée par défaut + tracée » : CODEOWNERS `@picmakpro` + revue code owner).
**Success Criteria** (what must be TRUE):

  1. `gh api repos/picmakpro/vibeflow-os/rulesets` ne rend plus `[]` : un ruleset actif sur
     `main` exige le statut CI vert avant merge (PROT-01).

  2. Une PR rouge est **refusée par défaut** ; la contourner demande un **geste explicite** et
     laisse une **trace dans GitHub** — prouvé en deux temps par des essais réels tracés (refus
     d'un merge sans contournement sur une PR jetable ; trace d'un contournement lue dans les rule
     suites), références des PR dans le SUMMARY, jamais par la seule lecture de la configuration
     (PROT-01). *Reformulé le 2026-09-17 — arbitrage Samuel, AskUserQuestion session principale,
     2026-09-17 (P-1 du `41-CONTEXT.md`) : le bypass est accordé au rôle `write`, le libellé
     d'origine « ne peut pas être mergée » était inatteignable.*

  3. Le flux de release est rejoué vert sous la nouvelle règle : bump → PR → merge → tag annoté
     → release GitHub → `bash scripts/check-release-tag.sh --remote` ✓ ; la politique hotfix
     (ce qui peut contourner quoi, avec quelle trace) est écrite, emplacement tranché au cadrage
     (PROT-02, PROT-03).

  4. QUAL-01 s'applique si un gate naît (mutation rouge prouvée) ; sinon la phase n'en crée
     aucun et le dit.

> **PRÉMISSE RENVERSÉE le 2026-09-17** (constat et arbitrage Samuel, AskUserQuestion session
> principale, 2026-09-17) : le compte `picmakpro`, seul admin, appartient à un **tiers** ;
> `permissions` du dépôt = `admin: false, maintain: false, push: true`. **Aucun ruleset ne peut être
> posé dans cette session.** Les critères de succès 1, 2 et 3 ci-dessus sont **inatteignables sans
> accès admin** ; les décisions D-01 à D-08 du `41-CONTEXT.md` sont **suspendues** et les plans
> 41-01 (T2/T3), 41-04 à 41-09 et la partie « sous la règle » de 41-11 à 41-13 sont **différés en
> attente d'accès** (`BACKLOG.md` § « Protection de `main` côté GitHub — DIFFÉRÉ »). L'exécution a
> été arrêtée après 41-01 Task 1 (registre `41-PREUVES.md` conservé). Un **périmètre sans admin**
> (gardes in-repo visibles et tracées) est proposé à l'arbitrage — il remplacera les critères de
> succès de cette phase une fois tranché.

> **PÉRIMÈTRE SANS ADMIN EXÉCUTÉ ET CLOS le 2026-09-18** (option (a), arbitrage Samuel,
> AskUserQuestion session principale, 2026-09-17) : six plans neufs (41-14 à 41-19, ci-dessous)
> livrent trois gardes in-repo qui SIGNALENT et TRACENT sans jamais verrouiller — G-1
> `scripts/check-baseline-arbitrage.sh` (PROT-04), G-2 `scripts/check-gate-touche.sh` (PROT-05),
> G-3 `scripts/check-push-sans-pr.sh` (PROT-05) — plus la doctrine `docs/ADR.md` § ADR-072
> (PROT-03) et O-3 du `25-SECURITY.md` portée à **« signalée et tracée »**. Ledger
> `.planning/REQUIREMENTS.md` : PROT-02/03/04/05 **cochés sur pièce** ; **PROT-01 reste NON COCHÉ** (depuis cochée le 2026-09-24)
> — hors d'atteinte sans accès admin, déclencheur de reprise écrit. **Les critères de succès 1, 2
> et 3 ci-dessus restent INATTEIGNABLES sans accès admin** (constat explicite,
> `41-PREUVES.md` § 41-19) et ne sont **pas** réécrits ici — ils décrivent la posture serveur
> différée, pas le périmètre livré. Critère 4 (QUAL-01) satisfait : 3 gates neufs, 29 mutants
> mesurés tués au total (G-1=9, G-2=6, G-3=5, plus les deux outils de phase). Rejeu final `gates`
> rc=0 (13 étapes) et `tests` rc=0 (82 suites, 0 échec). Les plans 41-01 (T2/T3), 41-02, 41-04 à
> 41-09, 41-11 à 41-13 restent **différés faute d'accès admin**, tels quels, non exécutés
> (`BACKLOG.md` § « Protection de `main` côté GitHub — DIFFÉRÉ »).

**Reprise du volet admin le 2026-09-23** : accès admin constaté (`picmakpro`, Willy), contournement
par deux utilisateurs nommés (D-02bis, arbitrage Willy, AskUserQuestion session principale,
2026-09-23), plans 41-01 à 41-13 révisés puis vérifiés (vérificateur frais, passé). Voir
`41-CONTEXT.md` § REPRISE.

**Chaîne des mesures confiée à Willy le 2026-10-02** (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Les confier à Willy », puis étendu le même jour, même canal : « Toute la chaîne à Willy ») : les plans 41-07, 41-08 et 41-09 mesurent la protection posée par Willy et dépendent de ses gestes d'admin (checkpoint avant le merge `--admin` de #101, clé de déploiement temporaire). Les plans 41-10, 41-11, 41-12 et 41-13 prolongent cette chaîne (chacun dépend du précédent) et sont confiés eux aussi à Willy. Tous sortent du périmètre de clôture de `fiabilite-v1.0` ; la Phase 41 est livrée sur 41-01 à 41-06 (+ 41-14 à 41-19), ces mesures résiduelles sont déclarées, aucun PLAN supprimé. `fiabilite-v1.0` se clôt avec **PROT-01 cochée le 2026-09-24 sur la pose des rulesets, complément attendu** : la mesure du refus réel d'un push direct (41-09, complément en 41-13) est confiée à Willy (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02). 41-07 est partiellement entamé (lignes `PR-R-*` de `41-PREUVES.md`, 2026-09-24).

**Plans:** 12/19 plans executed en 13 vagues séquentielles (planifiés le 2026-09-17, vérificateur frais 3 tours),
dont 10 **différés faute d'accès admin** ; seul 41-01 Task 1 est livré. **Six plans supplémentaires
(41-14 à 41-19) ajoutés et exécutés le 2026-09-18** pour le périmètre sans admin (option (a)) — voir
liste ci-dessous.

Plans:

- [x] 41-01-PLAN.md — préalables re-mesurés (identité admin, collaborateurs, #29, checks requis), JSON des deux rulesets à deux `User` `always` (D-02bis, révisé 2026-09-23)
- [x] 41-02-PLAN.md — `.github/CODEOWNERS` étroit, ledger PROT-01..04 non cochés
- [x] 41-03-PLAN.md — ADR-072 (contournement et hotfix), amendement d'ADR-059, `CLAUDE.md`
- [x] 41-04-PLAN.md — rejeu des gates, PR de la phase mergée avant toute pose (humain)
- [x] 41-05-PLAN.md — décision explicite avant pose, pose par l'exécutant, relecture serveur des deux `User`, état des PR en vol, mesure M-2 (révisé 2026-09-23)
- [x] 41-06-PLAN.md — preuve de la revue code owner (baseline comprise), refus sans contournement — `CO-VERDICT: ECART` accepté et documenté (Willy, 2026-09-24) : `mergeStateStatus`/`reviewDecision` masqués par le contournement `always` des deux seuls collaborateurs
- [ ] 41-07-PLAN.md — PR rouge jetable : mesure M-1, refus, fermeture sans merge — **CONFIÉ À WILLY, hors clôture de `fiabilite-v1.0`** (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Les confier à Willy ») ; partiellement entamé : lignes `PR-R-*` de `41-PREUVES.md` (2026-09-24).
- [ ] 41-08-PLAN.md — contournement réel et trace dans les rule suites, mesure M-3 — **CONFIÉ À WILLY, hors clôture de `fiabilite-v1.0`** (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Les confier à Willy »).
- [ ] 41-09-PLAN.md — push direct refusé pour un acteur hors liste (clé de déploiement temporaire), règles de tags, mesure M-4 (révisé 2026-09-23) — **CONFIÉ À WILLY, hors clôture de `fiabilite-v1.0`** (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Les confier à Willy »).
- [ ] 41-10-PLAN.md — doctrine post-preuves (O-3 « gardée par défaut + tracée », BACKLOG, ADR-072) — **CONFIÉ À WILLY, hors clôture de `fiabilite-v1.0`** (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Toute la chaîne à Willy »).
- [ ] 41-11-PLAN.md — décision du mode de release (« Quand publier »), bump éventuel, PR des preuves entrée sur `main` sans contournement (révisé 2026-09-23) — **CONFIÉ À WILLY, hors clôture de `fiabilite-v1.0`** (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Toute la chaîne à Willy »).
- [ ] 41-12-PLAN.md — tag, release GitHub, `check-release-tag --remote`, invariants de phase (humain) — **CONFIÉ À WILLY, hors clôture de `fiabilite-v1.0`** (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Toute la chaîne à Willy »).
- [ ] 41-13-PLAN.md — clôture : PROT-01 coché sur preuve, ROADMAP/STATE, éligibilité de la clôture du jalon (révisé 2026-09-23) — **CONFIÉ À WILLY, hors clôture de `fiabilite-v1.0`** (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Toute la chaîne à Willy »).

Plans du périmètre sans admin (option (a), ajoutés et exécutés le 2026-09-18) :

- [x] 41-14-PLAN.md — G-1 `scripts/check-baseline-arbitrage.sh` (PROT-04) : hausse de baseline ou sentinelle neutralisée sans arbitrage cité, 9 mutants
- [x] 41-15-PLAN.md — outillage de preuve de phase (`tools/check-aucune-fermeture.sh`, `tools/check-trace-arbitrage.sh`, `41-PREUVES.md`)
- [x] 41-16-PLAN.md — G-2 `scripts/check-gate-touche.sh` (PROT-05) : surface de gate touchée sans marqueur déclaratif `Gate-Touche:`, 6 mutants
- [x] 41-17-PLAN.md — G-3 `scripts/check-push-sans-pr.sh` (PROT-05) : alarme après coup sur un push direct vers `main` sans PR associée, 5 mutants
- [x] 41-18-PLAN.md — doctrine : ADR-072, résumé `CLAUDE.md`, renvois `BACKLOG.md`, O-3 « signalée et tracée »
- [x] 41-19-PLAN.md — clôture du périmètre sans admin : rejeu final, ledger `REQUIREMENTS.md` (PROT-01 non coché, PROT-02/03/04/05 cochés), constat d'inatteignabilité des critères 1-3

## 📋 Milestone ecc-inspiration-v1.0 — « ce qu'on emprunte à ECC » (Phases 51-56)

> Sections 51 à 56 et introduction du jalon archivées dans `.planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md`, à réinsérer au cadrage de la 51 (`gsd-discuss-phase 51` lit `### Phase 51:` ; la checklist 51-56 et l'entrée `## Milestones` restent ici).

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — jalon ecc-inspiration-v1.0 : introduction et Phases 51 à 56, aucun dossier de phase, non démarré (réinsérer au cadrage de la 51) -->

## 📋 Milestone equipe-produit-v1.0 — « l'équipe produit » (Phases 57-66)

**Milestone Goal :** VibeFlow sert une **équipe** et plus seulement un humain qui a tous les modules. Il apporte des
rôles de poste (solo par défaut, product, dev), des artefacts amont lisibles par un non-dev, et un état partagé entre
clones, sans recréer de couche de personas synonymes. Un rôle est **une vue, pas un droit** : git ne tient aucun
cloisonnement humain, et la doc le dit dès sa première ligne. Spec :
`docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md`. Germe : `.planning/seeds/SEED-001-equipe-produit-v1.md`,
dont les douze arbitrages A-01 à A-12 du 2026-09-16 tiennent, sauf A-09 (révisé ci-dessous). Doctrine :
`.planning/notes/2026-09-16-doctrine-agentique-ouverte-collaboration-humaine.md`.

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — equipe-produit-v1.0 : paragraphes Inscription et Révision d A-09 -->

**Être inscrite ne vaut pas feu vert.** Chaque phase passe par `gsd-discuss-phase` puis `gsd-plan-phase`. Ses exigences
sont posées au cadrage, jamais avant, dans les familles réservées et vérifiées libres le 2026-10-08 : `DLWS` (57),
`RLPO` (58), `PRDT` (59), `ARCG` (60), `COLB` (61), `PLTF` (62). `ROLE` était déjà pris, 41 occurrences.

**Critères de succès du jalon** (spec §9) :
1. Une install `VF_ROLE=product` n'expose aucune commande dev et pose `conductor` et `consolidator`.
   (Précisé le 2026-10-20, Q19, arbitrage Samuel, AskUserQuestion session principale, 2026-10-20 : « commande dev » = skills et agents des 3 modules `roles:["dev"]` + gsd-* ;
   superpowers reste posé en product par la chaîne design.)
2. Une install sans rôle reste **identique** à aujourd'hui : non-régression, suites existantes vertes.
3. Depuis un lab vide, le rôle product produit `BRIEF.md` et un PRD (`PROJECT.md` + `REQUIREMENTS.md`) jugés
   au-dessus du seuil par `prd-gate`. Le head refuse ensuite le découpage tant que l'architecture n'est pas validée.
4. Deux humains, deux clones, deux rôles, un workstream : trois semaines sans divergence subie en silence.
5. Aucun agent neuf au-delà de 250 lignes ; tous passent `check-agents.sh --strict`.
6. Zéro nom de client dans le dépôt (dépôt public).

**Ce que ce jalon ne fait pas** (spec §5.5) : pas de contrôle d'accès, pas de SaaS ni de Notion, pas de fork ni de copie
de prompts BMAD (marques protégées, aucun module nommé « BMAD »), pas de nouveau moteur de planning, pas d'agent
« scrum master » (`vf-dev-manager` l'est déjà).

**Collisions avec le jalon de Willy, à vérifier au cadrage de chaque phase :** l'installeur et `module.json` (58), à
côté de sa Phase 42 livrée ; `planning-core` (59, gabarit `product`) ; `conductor` et le kernel (57). Un seul écrivain
à la fois par module, rebase avant merge.

**Critère transverse (QUAL-01) :** tout gate ou hook livré naît avec ses trois issues et sa mutation rouge prouvée, en
forme exec (ADR-071).

### Phase 57: Verrou de driver par compartiment
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 57 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-57-*) -->

**Goal:** `driver-lock.sh` devient compartiment-aware : un verrou nommé par workstream, et un amendement daté d'ADR-053 change l'invariant en « un manager **par compartiment** ». `guard-driver-lock.sh` est aligné. Le head passe `--ws` et un `GSD_SESSION_KEY` distinct **par manager**. Un lab non partitionné garde exactement le comportement d'aujourd'hui.
**Requirements**: DLWS-01 à DLWS-08
**Depends on:** aucune. Première du jalon.

### Phase 58: Rôles de poste — installeur, profils solo / product / dev
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 58 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-58-*) -->

**Goal:** `/vibeflow-install` demande le rôle sur ce projet, pré-coché « solo », avec un mode non interactif par `VF_ROLE`. `module.json` porte `roles` (absent = tous), et `build-module-catalog.sh` filtre le catalogue. Le rôle vit dans un fichier local non versionné (A-11) ; le projet ne porte que la liste des rôles autorisés, vérifiée par `check-role-consistency.sh`. Trois profils seulement (A-02).
**Requirements**: RLPO-01, RLPO-02, RLPO-03, RLPO-04, RLPO-05, RLPO-06, RLPO-07, RLPO-08, RLPO-09, RLPO-10, RLPO-11, RLPO-12
**Depends on:** 57.

### Phase 59: Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 59 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-59-*) -->

**Goal:** Un bundle produit sur le moule de `business-pilot-bundle`. La front door `vibeflow-product`, sur le moule de `vibeflow-design`, produit `BRIEF.md` (le seul fichier nouveau, A-06) et le PRD (`PROJECT.md` + `REQUIREMENTS.md`, gabarit `product` de `planning-core`). Un juge frais `prd-gate`, en lecture seule et sur rubric /100, rend éliminatoire toute exigence sans critère d'acceptation. `vibeflow-head` lit le rôle pour rediriger au lieu de dispatcher `vf-coder` (A-05). Le bundle reste `proposable: false` jusqu'à preuve sur un lab réel (Q-09, défaut probable).
**Requirements**: PRDT-01..PRDT-12 (posées à la planification, 2026-10-27).
**Depends on:** 58.

### Phase 60: Gate architecture avant découpage et validation des phases proposées
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 60 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-60-*) -->

**Goal:** Un gate séparé assemble l'existant : `software-architecture` et GSD (`gsd-map-codebase`, `gsd-graphify`). Le head refuse le découpage en phases tant que `ARCHITECTURE.md` n'est pas validée (A-08). Une phase ajoutée par le rôle product ou par le head reste **proposée** jusqu'à sa validation par un dev ; en solo, elle est auto-validée. Le mécanisme passe par un marqueur sur la phase et `check-phase-validation.sh` (A-07).
**Requirements**: ARCG-01, ARCG-02, ARCG-03, ARCG-04, ARCG-05, ARCG-06, ARCG-07, ARCG-08, ARCG-09, ARCG-10, ARCG-11 (posées à la planification, 2026-10-29, dérivées de P60-D-01..14 et P60-H-01..04 sans arbitrage neuf).
**Depends on:** 59.

### Phase 61: Collaboration à deux humains — divergence armée, preuve sur lab réel
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 61 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-61-*) -->

**Goal:** Pour un lab multi-humains, `check-divergence.sh` et son hook `post-merge` sont armés par défaut. Le champ `role:` s'ajoute aux entrées des registres (DECISIONS, LEARNINGS, BLOCKERS). La preuve est faite à **deux humains, deux clones, deux rôles, un workstream** sur un lab réel, pas sur un clone jetable (spec §9, critère 4 ; spec head §6, point 4).
**Requirements**: COLB-01, COLB-02, COLB-03, COLB-04, COLB-05, COLB-06, COLB-07, COLB-08, COLB-09 (COLB-08, preuve sur lab réel, reste décochée : P61-B-01 et P61-B-02)
**Depends on:** 57 et 60.

### Phase 62: Décision sur l'approche plateforme, sur preuve
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 62 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-62-*) -->

**Goal:** Une décision écrite sur l'approche C de la spec (plateforme collaborative : hub, base centrale), prise sur mesure : le besoin non-dev sans terminal est-il réel (Q-06) ? À défaut de preuve, le jalon se clôt sur un déclencheur daté de reprise. Aucun code avant la décision.
**Requirements**: PLTF-01, PLTF-02
**Depends on:** 61.

### Phase 63: Règles produit empruntées à AIDD

**Goal:** Les règles de l'amont produit d'AIDD (`ai-driven-dev/framework`, MIT) sont reprises au plus près, dans notre vocabulaire et nos fichiers, pour compléter ce que posent les Phases 59 et 60 : Three Amigos en trois juges frais (produit, delivery, qualité) avec une réconciliation où « silence, majority, and severity are not approval » ; grille des zones d'ombre (7 catégories, 3 sévérités, une question par trou, comparaison entre deux passes) ; table preuve / hypothèse / décision du BRIEF ; change set gelé avant écriture, montré au dev qui valide une phase proposée (A-07) ; grille INVEST et découpe verticale pour cette validation ; scénarios de QA tirés d'un critère d'acceptation, jamais du diff ; définition de « prêt à planifier » avec refus routé vers l'artefact refusé ; section unique des questions ouvertes (`TBD: <question>`) que `check-prd.sh` admet là et refuse ailleurs.
**Requirements**: TBD — famille réservée au cadrage.
**Depends on:** 59, 60.
**Sources:** `docs/research/2026-10-29-aidd-equipe-produit-inventaire.md` (inventaire atomique, chemins AIDD exacts) ; `docs/research/2026-10-29-ai-driven-dev-framework.md` ; SEED-001 A-02, A-06, A-07, A-10.
**Hors périmètre :** le vocabulaire AIDD (epic, story, task : couche de synonymes, Q-11) ; les dossiers `aidd_docs/` et tout fichier amont au-delà de BRIEF, PROJECT, REQUIREMENTS (A-06) ; les modes autonomes de `02-backlog` et le mode `auto` de `01-sdlc` (ADR-031) ; un nom d'agent « three amigos ». Copie mot pour mot d'un gabarit AIDD : seulement avec un fichier NOTICE MIT.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 63 to break down)

### Phase 64: Contrôles après exécution branchés en nœuds du plan de bataille

**Goal:** Les contrôles que GSD promet après exécution tournent enfin. Mesure du 2026-10-29 : 15 VALIDATION sur 20 non conformes (`nyquist_compliant: false`), 0 LEARNINGS (que le planificateur lit pourtant), 0 UAT, 13 VERIFICATION `human_needed` ou `gaps_found` jamais reprises — les hooks internes du workflow GSD qui devaient les déclencher ne sont jamais observés. Chaque contrôle devient un **nœud explicite du plan de bataille** de `vf-dev-manager`, déclenché par un fait constatable sur disque, jamais par l'humain : (1) `gsd-extract-learnings` si VERIFICATION `passed` et pas de LEARNINGS ; (2) `gsd-audit-uat` en début de mission s'il reste une VERIFICATION ou une UAT ouverte ; (3) `gsd-assumptions-analyzer` en éclaireur avant un cadrage sans CONTEXT.md ; (4) `gsd-secure-phase` par `vf-auditer` (outil `Skill` à lui donner) quand le PLAN porte un registre de menaces ; (5) `gsd-validate-phase` en mandat `vf-coder` si `nyquist_compliant: false` ; (7) `gsd-verify-work` **proposé**, jamais imposé, par le manager si VERIFICATION `human_needed` : l'humain peut le **contourner** d'un geste (recette jugée redondante ou trop coûteuse à tester), et ce contournement est un statut à part entière — tracé dans la VERIFICATION (qui, quand, motif), compté comme clos par `audit-uat`, par la ROADMAP et par les gates de suivi — pour qu'une recette refusée ne reste jamais une dette ouverte dans la doc ni dans le suivi de projet (arbitrage Samuel, message session principale, 2026-10-29). Les juges en lecture seule de l'étage de vérification partent en un seul message.
**Requirements**: TBD — famille réservée au cadrage.
**Depends on:** aucune phase de ce jalon.
**Sources:** `docs/research/2026-10-29-etude-gsd-skills-agents-non-utilises.md` (classement complet, déclencheurs, tailles) ; `docs/research/2026-10-29-etude-cout-gsd.md` ; `plugin/dev-orchestrator/references/mission-flow.md`, `mission-contracts.md`.
**Hors périmètre :** les correcteurs automatiques (`gsd-audit-fix`, `gsd-code-fixer` : ADR-031) ; les briques classées 6, 8, 9, 10 et suivantes du rapport (inscriptibles ensuite) ; la réécriture de ces skills dans VibeFlow (étape E3 de SEED-003) — ici on les branche, on ne les réécrit pas.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 64 to break down)

### Phase 65: Révision des règles qui brident l'efficacité des agents

**Goal:** Les règles de VibeFlow qui limitent l'efficacité des agents sans contrepartie mesurée sont revues sur mesure : (a) la garde `check-ajout-retrait.sh` (SOBR-05) ne surveille plus que la documentation de méthode (ADR, CLAUDE.md, règles), plus les SKILL.md, scripts de garde et mémoires d'agent ; (b) le plafond de 2 agents en parallèle, posé après le crash du 2026-10-22 sans mesure, est remplacé par une valeur mesurée (mémoire consommée par agent sur ce poste), cohérente avec `max_concurrent_agents` ; (c) la « voie unique » de `vf-coder` ne s'applique plus aux juges en lecture seule, qui n'ont aucun étage à sauter ; (d) `vf-auditer` est dispatché sur un fait constatable (`mission-flow.md` §3), plus au jugement ; (e) les déclencheurs des briques dormantes sont réécrits en conditions machine ; (f) la profondeur de dispatch (limite du harness mesurée le 2026-09-17) est re-mesurée sur la version courante de Claude Code et les flux qui la heurtent (`gsd-debug` lancé depuis `vf-coder`) sont redessinés. (g) la CI cesse d'être un frein : mesure du 2026-10-29, 37 min de suites en série dont 17,3 min pour les seuls mutants du guard de verrou, et deux runs par commit de PR (push + pull_request) — suites réparties en shards parallèles, mutants joués seulement quand ils ont quelque chose à juger et sur tout push de `main`, run obsolète d'une PR annulé, `push` réservé à `main` (arbitrage Samuel, message session principale, 2026-10-29 : « on corrige le maximum », revue faite par nous, merge sans attendre la revue `@picmakpro`). (h) les mutants du guard de verrou sont répartis sur plusieurs jobs : après le volet (g), ce sont eux seuls qui fixent la durée d'un push de `main`. Mesure du 2026-10-29 (run 40910106649, `main` sur `d41afc88`) : les 7 shards finissent entre 2 min 30 et 6 min 30, le job des mutants dure 28 min 45 (19 min 50 sur la PR #181). Constat : les 59 mutants (`MUT_TOTAL`, `test-guard-driver-lock-ws.sh`) sont lancés tous ensemble en arrière-plan dans un seul job, avant un `wait` unique ; sur un runner à 4 cœurs, ils se disputent la machine. Comme ils sont indépendants (chacun a sa copie du guard et son `WORK_DIR`), on peut les répartir. Piste : un sélecteur de tranche dans la suite (même principe que `ci-shard-suites.sh`, partition déterministe par indice), une matrice de jobs de mutants, et un agrégateur qui contrôle que l'union des tranches couvre exactement les `MUT_TOTAL` mutants, sans doublon ni tranche vide (un mutant perdu doit rougir), avec un témoin rouge joué avant de conclure. Cible : un push de `main` vers 8 à 10 min. La PR #171 (autre session, borne de parallélisme des mutants dans un même job) touche la même boucle : elle est à reprendre ou à fermer avec ce volet, pas à merger à côté (arbitrage Samuel, message session principale, 2026-10-29 : « effectivement, je pense que ça serait une bonne idée », versé dans la Phase 65). (i) le cas KC2 de `test-check-method-budget.sh` (trois passes d'archivage simultanées sur la même source, `par3`) cesse de rougir au hasard : il est connu pour être instable en CI et se règle aujourd'hui en relançant le job à la main, ce qui coûte un cycle complet de CI. Constaté de nouveau le 2026-10-29 sur la PR #183 (run 40932241571, shard 6 : « KC2 — aucun refus » et « KC2 — les trois rendent 0 (rc 0 ≠ 1) »), qui ne touchait que la ROADMAP ; vert à la relance. Il faut établir la cause (une course dans le verrou d'archivage, qui serait un vrai défaut, ou une attente du test trop juste sur un runner chargé) avant de corriger, et ne jamais affaiblir l'assertion pour la faire passer : le mutant MU34 (verrou retiré) doit continuer à faire rougir KC2 (arbitrage Samuel, message session principale, 2026-10-29).
**Requirements**: TBD — famille réservée au cadrage.
**Depends on:** aucune phase de ce jalon ; à jouer avant ou avec la 64 si le parallélisme de l'étage de vérification en dépend.
**Sources:** `docs/research/2026-10-29-etude-gsd-skills-agents-non-utilises.md` § règles qui brident ; `plugin/conductor/scripts/check-ajout-retrait.sh` ; mémoires « parallélisme plafonné à 2 » et « profondeur de spawn limitée à 2 ».
**Hors périmètre :** lever une limite technique du harness par décision ; toucher ADR-031 ou le ship gaté humain.
**Plans:** 0 plans

Plans:

- [x] 65-01 — accélération de la CI, volet (g) : `scripts/ci-shard-suites.sh`, mode `GW_MODE=sans-mutants`, jobs `changes` / `tests-shard` / `tests-mutants` / agrégateur au nom requis inchangé (exécuté hors plan formel, sur demande de Samuel, 2026-10-29)
- [ ] TBD — volets (a) à (f), (h) et (i) (run /gsd-plan-phase 65 to break down)

### Phase 66: Grille de sévérité des juges et convergence des boucles de revue

**Goal:** Une même grille de sévérité s'applique à TOUS les juges de VibeFlow (`vf-reviewer`, `vf-design-judge`, `prd-gate`, juges adverses briefés par les managers, relecture SOBR-04), pour que les boucles de revue convergent au lieu de produire un « nouveau majeur » à chaque tour :
- Un défaut n'est **majeur** que s'il cumule trois conditions : (1) il est démontré par une sonde exécutée ; (2) l'entrée est plausible de bonne foi, pour un agent de l'équipe ou un humain qui suit le gabarit (une faute de frappe compte, une obfuscation volontaire non) ; (3) la conséquence est réelle et sans filet : faux vert non rattrapé par la couche suivante, faux rouge sans contournement, promesse écrite contredite, ou régression.
- Tout le reste est **mineur** et ne bloque pas le merge.
- Le juge rapporte la **famille**, pas l'instance. Le correctif ferme la famille, de préférence en comparant à des données réelles plutôt qu'en ajoutant des motifs. Une variante d'une famille fermée ne rouvre rien.
- Le dernier tour est rejoué par un juge frais briefé avec la grille.
**Validation:** proposed

**Constat qui la motive :** Phase 59, contrôle heuristique `check-prd.sh` : quatre juges frais d'affilée ont chacun trouvé un « nouveau majeur ». Phases 60 et 61 jugées avec la grille : chaque tour a trouvé au plus un majeur légitime (le contournement par l'identifiant a été rouvert deux fois, jusqu'à ce que la famille soit fermée par comparaison aux identifiants réels) ; les deux phases ont convergé en v2.74.0.
**Source :** arbitrage Samuel, AskUserQuestion session principale, 2026-10-29 : « Oui, valide la grille pour 60 et 61. Ensuite, il faudra généraliser au maximum cette solution. »
**Rattachement :** graine `.planning/seeds/SEED-002-convergence-des-boucles-de-revue.md` (convergence des boucles de revue, veille Elephant-Goldfish).
**Requirements**: TBD — famille `GRIL` réservée, posée au cadrage.
**Depends on:** aucune phase bloquante.
**Hors périmètre :** toute baisse d'exigence sur les défauts réellement majeurs.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 66 to break down)

## 📋 Milestone vibeflow-v2.0 — « le cockpit VibeFlow » (Phases 67-81)

**Milestone Goal :** un saut d'usage visible pour qui installe VibeFlow : un cockpit qui montre le projet, le code
et qui est au travail, dans tout lab GSD, sur un socle partagé avec le panneau compact `vf-signal`. Le cockpit
floorplan remplace le module `vf-cockpit` (page Mermaid, branche `feat/vf-cockpit-module`, jamais mergée). Entrée du cadrage :
`.planning/notes/2026-11-01-cockpit-facettes.md` ; savoir technique : skill local `spike-findings-vibeflow-os`,
`.planning/spikes/WRAP-UP-SUMMARY.md` (spikes 002 à 006) et `docs/research/2026-11-01-etude-floorplan-cockpit.md`.

**Publié au 2026-11-11 :** la Phase 67 en `v2.75.0` (2026-11-03) ; les Phases 68, 69, 70, 71, 71.5, 72 et 78 en `v2.76.0` (2026-11-06, PR de release #217,
module `cockpit` v1.4.0). Rien n'est publié depuis : gel des publications (décision de Samuel du 2026-11-08, `.planning/missions/2026-11-08-recette-correctifs.md`) ;
le travail postérieur vit sur `release/v2.77.0` (PR #226).

**Inscription :** 2026-11-01, arbitrage Samuel, AskUserQuestion session principale, 2026-11-01 (cockpit en tête du
jalon ; `equipe-produit-v1.0`, phases 63-66, reste ouvert ; la réponse initiale « go » a été reclarifiée par une seconde
question). Même forme qu'ECC : section distincte de la ROADMAP plate, **sans `gsd-new-milestone`**. Numéros 67-70 posés à la
main (le moteur propose un mauvais numéro sur ce dépôt ; 36 reste réservé, dossier orphelin ; 42-50 : compartiment `gouvernance`).
La graine `SEED-004` (retrait de `vf-cockpit`) est encore `dormant` au 2026-11-11 alors que son déclencheur, la livraison de la Phase 67, est atteint depuis `v2.75.0`.

**Phase 69 :** inscrite le 2026-11-03, option A de `.planning/notes/2026-11-03-cockpit-progression-en-cours.md`
(arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 ; inscription demandée par Samuel en session principale, même date).
Cadrage mis à jour le même jour : la 69 couvre aussi l'équipe au travail (P69-D-12..24).

**Phases 71 et 72 :** inscrites le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 : « 69 = avancement + équipe,
terminal en 71 (Recommandé) », puis « Oui, 69 / 71 / 72 (Recommandé) »). **Ordre du jalon :** 69 → 68 → 70 → 71 → 72 (même arbitrage :
« 69 → 68 → 70 → 71 → 72 (Recommandé) ») ; la 72 dépend de la 71.

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
principale, 2026-11-08, option recommandée) : lot 0 → 79 et 80 en parallèle, 73 dès le lot 0 livré → 74 après la 79 → 75 → 76 → 77 ;
81 seulement si Samuel le décide (`AUDC-Q3`). **Décisions de fond tranchées le 2026-11-11** (registre § 5.1, Samuel retenant l'avis de
la session principale) : fork du moteur assumé, index des sessions sur disque avec fenêtre de 24 h, `claude agents` en source de
référence, Phase 81 reportée.

### Phase 67: Cockpit floorplan sur socle partagé
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 67 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-67-*) -->

**Goal:** Un module VibeFlow distribué et toggable ouvre, dans tout lab GSD, un cockpit à onglets Projet (au cœur) et Code, sur un socle partagé (collecteur « qui est au travail » + graphe Projet) que `vf-signal` réutilise ; il remplace le module `vf-cockpit` jamais mergé.
**Requirements**: CKPT-01..CKPT-12
**Depends on:** rien dans le jalon.

### Phase 68: Embarquer vf-signal sur le socle partagé
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 68 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-68-*) -->

**Goal:** Le mod `vf-signal` (aujourd'hui dans `~/.claude/mods/vf-signal`) est embarqué dans le plugin `vibeflow`, branché sur le socle partagé de la Phase 67, avec un bouton « Ouvrir le cockpit » ; il est livré dans une release.
**Requirements**: VFSG-01..VFSG-13
**Depends on:** Phase 69 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 : « 69 avant 68 ») ; Phase 67 en amont.

### Phase 69: Suivi du travail en cours dans le cockpit
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 69 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-69-*) -->

**Goal:** La carte Projet du cockpit dit où en est vraiment une phase : un état dérivé de traces locales (`a-faire`, `en-cours`, `a-recetter`, `fait`), un décompte des plans qui ne mêle plus les correctifs de mission, les missions rattachées à leur phase, un jalon qui n'affiche plus « 0 % à faire » quand ses plans sont exécutés ; la règle STATE → statut, seule source fausse, est retirée. Elle montre aussi l'équipe au travail : l'arbre session → manager → workers relié aux nœuds de mission, la dernière action lisible de chaque agent, un onglet « Équipe » et le transcript réduit d'un agent, lu à la demande.
**Requirements**: CKPT-13..CKPT-28
**Depends on:** Phase 67 (le module `plugin/cockpit` et sa lib de lecture `readPlanning` existent). La Phase 68 en dépend et consommera l'objet `avancement` (P69-D-10).

### Phase 70: Finitions UI du cockpit
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 70 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-70-*) -->

**Goal:** Le cockpit tient en largeur mobile avec une information hiérarchisée, sa visite guidée est plus claire, et le chrome ne montre plus d'anglais résiduel ni de coquilles.
**Requirements**: UIFN-01, UIFN-02, UIFN-03, UIFN-04, UIFN-05, UIFN-06, UIFN-07, UIFN-08, UIFN-09, UIFN-10, UIFN-11, UIFN-12, UIFN-13, UIFN-14
**Depends on:** Phase 67 ; Phase 69 pour l'exécution (mêmes fichiers du cockpit, P70-D-14).

### Phase 71: Terminal intégré au cockpit
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-05.md — Phase 71 (corps : critères, plans, historique ; plans et critères aussi dans phases/VFDO-71-*) -->

> **Exécutée le 2026-11-04, mergée (PR #203, `d4171ded`, 2026-11-04T23:52:41Z), recettée et close le 2026-11-05** (`71-RECETTE-HUMAINE.md`, FAITE) : 11 plans faits, revue et audit de sécurité complet passés avec corrections (`71-SECURITY.md`). La recette par juges a été jouée (P71-D-32), puis Samuel a joué Arc, Firefox, Safari (écart corrigé par la PR #209) et le clavier AZERTY réels le 2026-11-05. **Cadrée le 2026-11-03** (`71-CONTEXT.md`, P71-D-01..17 ; arbitrages Samuel, AskUserQuestion session principale Claude Code, 2026-11-03). Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 : « Terminal intégré dans la page »).
**Goal:** Le cockpit ouvre un terminal dans la page (xterm.js et une PTY native), à la racine du lab, sans changer d'outil ; un audit de sécurité complet accompagne la phase, parce qu'un shell complet derrière le serveur local change le modèle de menace du cockpit.
**Requirements**: TERM-01, TERM-02, TERM-03, TERM-04, TERM-05, TERM-06, TERM-07, TERM-08, TERM-09, TERM-10, TERM-11, TERM-12
**Depends on:** Phase 67 (serveur unique) ; ordre du jalon : après la 70 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 : « 69 → 68 → 70 → 71 → 72 (Recommandé) »).

### Phase 71.5: Réexamen du design system du cockpit (INSERTED)
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11.md — Phase 71.5 (corps : demande d'origine mot pour mot, plan de bataille ; décisions aussi dans phases/VFDO-71.5-*) -->

> **Exécutée les 2026-11-05 et 2026-11-06, publiée en `v2.76.0` (PR #213, reprise par merge commit dans la PR de release #217, `de19669b`)** : mission design de `vf-design-manager`, sans plan GSD ; registre `P71.5-D-xx` dans `71.5-CONTEXT.md` ; juges de rendu frais au-dessus du seuil de 70 (coque 85, Code 79, Projet 76, Équipe et « Au travail » 74, tiroir 84) et retour de Samuel du 2026-11-06, consignés à l'entrée v1.3.4 de `plugin/cockpit/CHANGELOG.md`.
**Goal:** En partant de l'existant (`DESIGN.md`, direction « Graphite », et jetons de `viewer.html`), le design system du cockpit (`plugin/cockpit/`) est réexaminé : (1) priorité aux couleurs, qui doivent porter du sens (statut, sévérité, type de carte) et sortir du terne, contraste AA mesuré dans les deux thèmes ; (2) les espacements suivent une seule échelle de jetons, appliquée partout ; (3) icônes, hiérarchie des vues et informations utiles à afficher sont proposées comme des choix. Ordre : une direction d'abord (audit avec captures, 2 ou 3 directions de palette en maquettes jetables sur les vrais écrans Projet, Code et Équipe), tranchée par Samuel, puis `DESIGN.md`, jetons et application. L'en-tête : couleurs et hiérarchie proposables, structure et contenus à la Phase 78.
**Requirements**: aucune exigence au ledger (« vert » = critique scorée ≥ 70/100 contre `DESIGN.md` par un juge frais, suites de mise en page existantes vertes).
**Depends on:** Phase 71 (mergée). Missions parallèles : Phases 72 et 78 (la 78 possède l'en-tête et la vue Git ; la 71.5 possède les jetons d'espacement et de couleur, que la 72 et la 78 consommeront).

### Phase 72: Lancer du travail depuis les cartes du cockpit
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11.md — Phase 72 (corps : cadrage, vision de Samuel mot pour mot, sources, plans ; plans aussi dans phases/VFDO-72-*) -->

> **Exécutée du 2026-11-05 au 2026-11-06, publiée en `v2.76.0` (PR #214, reprise par merge commit dans la PR de release #217, `de19669b`)** : 16/16 plans (72-16 ajouté le 2026-11-06, P72-D-20), audit de sécurité en trois lots (`72-SECURITY.md`, lot 3 : SECURED), recette par juge au SHA `4fa5fe95` avec un faux `claude`, rouges Linux de la PR #214 corrigés (`72-CI-LINUX.md`) ; LANC-01..11 cochées, LANC-12 décochée : la recette au vrai `claude` n'a pas été jouée.
**Goal:** Depuis une carte de phase ou de mission, ou depuis le cockpit, lancer du travail dans une session Claude Code qui tourne sur le poste, avec le contexte du projet, en anticipant les dépendances manquantes et les impossibilités avant de lancer.
**Requirements**: LANC-01, LANC-02, LANC-03, LANC-04, LANC-05, LANC-06, LANC-07, LANC-08, LANC-09, LANC-10, LANC-11, LANC-12
**Depends on:** Phase 71 (terminal intégré ; clôture mergée, cockpit v1.3.3).

### Phase 73: Gouvernance au cockpit — arbitrages en attente, worktrees et verrous

> **Non cadrée — cadrage par le manager à suivre.** Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

**Goal:** Le cockpit montre ce qui attend une décision humaine (arbitrages en attente, reliés à leur phase et à ce qu'ils bloquent), qui tient le verrou de driver, quels worktrees et branches existent avec leur travail non commité, et l'alerte du watchdog posée sur le nœud de mission concerné.
**Requirements**: TBD — posées au cadrage.
**Depends on:** Phase 69 (objet `avancement`, collecteur `who`) ; ordre du jalon : juste après la 69. Depuis l'audit du 2026-11-10 : après le lot 0 (états lus des sessions).
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 9, 13, 4) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 73 to break down)

### Phase 74: L'équipe dans le temps — swim-lanes, coût, replay

> **Non cadrée — cadrage par le manager à suivre.** Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

**Goal:** L'onglet Équipe montre les agents sur un axe de temps (une ligne par agent, colorée par nœud de DAG), le coût en jetons et en durée par mission, phase et agent, et rejoue une mission nœud par nœud avec un curseur temporel.
**Requirements**: TBD — posées au cadrage.
**Depends on:** Phase 69 (onglet Équipe, lien agent ↔ nœud) ; Phase 79 (index des transcripts, route de frise) ; ordre du jalon : après la 72. La Phase 79 est ajoutée depuis l'audit du 2026-11-10.
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 1, 2, 3) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 74 to break down)

### Phase 75: L'activité posée sur le code — hotspots, couplage, gardes, empreinte

> **Non cadrée — cadrage par le manager à suivre.** Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

**Goal:** La carte Code se colore par l'activité : fréquence de changement croisée avec la taille, fichiers qui changent ensemble, fichiers couverts par un gate ou une suite et zones sans témoin, fichiers lus ou modifiés par la mission en cours.
**Requirements**: TBD — posées au cadrage.
**Depends on:** Phase 67 (onglet Code) ; Phase 69 pour l'empreinte des agents ; Phase 79 (index des transcripts) ; ordre du jalon : après la 74. La Phase 79 est ajoutée depuis l'audit du 2026-11-10.
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 5, 6, 7, 8) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 75 to break down)

### Phase 76: Traçabilité au cockpit — exigences, décisions, mémoire

> **Non cadrée — cadrage par le manager à suivre.** Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

**Goal:** Le cockpit relie exigence → plan → SUMMARY → VERIFICATION → recette avec les trous en rouge, les décisions (ADR, arbitrages préfixés, commits qui les citent) en graphe navigable, et la mémoire des agents en graphe de liens avec ses entrées orphelines ou périmées.
**Requirements**: TBD — posées au cadrage.
**Depends on:** Phase 69 (rattachement des missions) ; ordre du jalon : après la 75.
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 10, 11, 14) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 76 to break down)

### Phase 77: Santé de la méthode et synthèse — jauges, dernière visite, burn-up

> **Non cadrée — cadrage par le manager à suivre.** Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

**Goal:** Le cockpit montre en jauges les budgets de la méthode (densité des agents, skills, taille du ROADMAP et du BACKLOG, baseline d'instructions), résume ce qui a changé depuis la dernière visite, et trace le burn-up du jalon en pourcentage strict.
**Requirements**: TBD — posées au cadrage.
**Depends on:** Phase 69 (avancement des phases et du jalon) ; Phase 79 pour le coût par phase ; ordre du jalon : après la 76. La Phase 79 est ajoutée depuis l'audit du 2026-11-10.
**Sources:** `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 12, 15, 16) ; audit du 2026-11-10 : `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 77 to break down)

### Phase 78: Git dans le cockpit — en-tête, graphe des worktrees et branches, données Git
<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-11-11.md — Phase 78 (corps : cadrage, demande de Samuel mot pour mot, plans ; plans aussi dans phases/VFDO-78-*) -->

> **Exécutée du 2026-11-05 au 2026-11-06 (reprise après le crash du 2026-11-05), publiée en `v2.76.0` (PR #216, reprise par merge commit dans la PR de release #217, `de19669b`)** : 11/11 plans, GITC-01..14 cochées ; critique design, audit de sécurité en lecture, revue et recette par juge navigateur consignés dans `.planning/missions/2026-11-06-phase-78-git-cockpit-reprise.md` (le dossier de phase ne porte ni `78-VERIFICATION.md` ni `78-SECURITY.md`).
**Goal:** L'en-tête du cockpit garde, sur les trois onglets, le nom du dossier du projet et montre la branche et le worktree courants sans encombrer ; un graphe façon « gitgraph » situe les worktrees et les branches du lab ; le cockpit montre des données Git du projet façon GitKraken, et les actions Git éventuelles suivent le périmètre arbitré au cadrage. La revue de diff complète est hors périmètre.
**Requirements**: GITC-01, GITC-02, GITC-03, GITC-04, GITC-05, GITC-06, GITC-07, GITC-08, GITC-09, GITC-10, GITC-11, GITC-12, GITC-13, GITC-14
**Depends on:** Phase 67 (serveur et onglets du cockpit) ; Phase 71 (modèle de menace des routes qui agissent sur le poste). En parallèle de la 72. Recoupements à trancher au cadrage : Phase 73 (worktrees, branches et travail non commité, idée 13) et Phase 75 (données tirées de `git log`) ; Phase 71.5 (jetons d'espacement et paddings, qu'elle possède).

### Phase 79: Socle du cockpit — une collecte, un flux, une route d'état

> **Cadrée et planifiée le 2026-11-11** par le manager de la phase (décisions déléguées par Samuel, message session principale, 2026-11-08, option recommandée ; arbitrages AUDC-Q2, Q4, Q5 du 2026-11-11 en vigueur). Contrats fournis aux Phases 73, 74, 75, 76, 77 et 80 : `79-CONTEXT.md` § « Contrats fournis » et amendements A1 à A29. Questions à Samuel, non bloquantes : S-1 à S-4.

**Goal:** Le serveur du cockpit collecte sans bloquer et sert un état unique : un index incrémental des transcripts, une route d'état en JSON lue par la page et par `vf-signal`, un seul flux d'événements partagé entre les onglets, des données sorties de la page, et un serveur lancé depuis le module plutôt que depuis une copie dans le lab.
**Requirements**: SOCL-01, SOCL-02, SOCL-03, SOCL-04, SOCL-05, SOCL-06, SOCL-07, SOCL-08, SOCL-09, SOCL-10, SOCL-11, SOCL-12, SOCL-13, SOCL-14, SOCL-15, SOCL-16, SOCL-17, SOCL-18, SOCL-19, SOCL-20, SOCL-21, SOCL-22, SOCL-23, SOCL-24, SOCL-25
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
**Plans:** 20 plans en 9 vagues

Plans:

- [ ] 79-01-PLAN.md — Fork assumé : retrait de l'appareil de patchs du moteur (vague 1)
- [ ] 79-02-PLAN.md — Aide commune de lancement du serveur dans les suites, migration (vague 1)
- [ ] 79-03-PLAN.md — Registre du verrou archivé 24 h, verbe registry, plan de mission publié (vague 1, conductor)
- [ ] 79-04-PLAN.md — Nœud écrit dans chaque mandat, doctrine de publication (vague 2, références)
- [ ] 79-05-PLAN.md — Table des routes, réponse gardée, annotateurs du graphe Code (vague 1)
- [ ] 79-06-PLAN.md — Serveur lancé depuis le module, sortie = données, empreinte, orphelin, mesure du confinement (vague 2)
- [ ] 79-07-PLAN.md — Résolution physique des chemins, cible interne protégée, pilotes git (vague 2)
- [ ] 79-08-PLAN.md — Index incrémental des transcripts et contrat de forme étendu (vague 2)
- [ ] 79-09-PLAN.md — Collecte hors de la boucle, registre lu, verrous projetés (vague 3)
- [ ] 79-10-PLAN.md — Traduction au point d'émission (vague 3)
- [ ] 79-11-PLAN.md — Plafond en colonnes et code navigateur rangé (vague 4)
- [ ] 79-12-PLAN.md — Route d'état et vf-signal par la route (vague 4)
- [ ] 79-13-PLAN.md — Route de frise et cibles en mémoire (vague 5)
- [ ] 79-14-PLAN.md — Flux partagé entre onglets et veille de silence (vague 5)
- [ ] 79-15-PLAN.md — Route graphe, fin de la réécriture de project.html, témoin d'export (vague 6)
- [ ] 79-16-PLAN.md — Coquille statique servie du module (vague 7)
- [ ] 79-17-PLAN.md — Magasin d'état côté page (vague 7)
- [ ] 79-18-PLAN.md — Mise en page dans un worker (vague 8)
- [ ] 79-19-PLAN.md — Journal des attentes par hook, détachable (vague 9)
- [ ] 79-20-PLAN.md — Documentation et version du module (vague 9)

### Phase 80: Trois onglets, trois formes — Projet en couloirs, clavier, navigation

> **Non cadrée — cadrage par le manager à suivre.** Inscrite le 2026-11-11 depuis l'audit du cockpit du 2026-11-10 (demande de Samuel, session principale Claude Code, 2026-11-10 ; numéro et découpage : décision déléguée par Samuel, message session principale, 2026-11-08, option recommandée).

**Goal:** L'onglet Projet se lit d'un regard à toute largeur (les phases rangées par état, le graphe à la demande), chaque carte du canevas est atteignable au clavier et nommée pour un lecteur d'écran, et l'on ne se perd plus sur la carte du code : un ajustement qui montre tout, une minicarte, une palette de commandes, des surcouches qui retiennent le focus.
**Requirements**: TBD — famille `FORM` réservée, posée au cadrage.
**Depends on:** Phase 71.5 (jetons de couleur et d'espacement) ; Phase 78 (en-tête). Les onglets sans rechargement attendent la Phase 79. En parallèle de la 79.
**Sources:** `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2 ; `2026-11-10-audit-cockpit/DESIGNS.md` § 6 et § 7 ; registre `AUDC-BL1`, `BL2`, `M1`, `M2`, `M5`, `M6`, `M8`, `M10`, `M12`, `X1` à `X3`, `X5`, `X7`, `X8`, `F1`, `F3` à `F5`, `F7`, `I23` à `I27`, `I29`, `I30`.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 80 to break down)

### Phase 81: Agir sur une session depuis le cockpit

> **Non cadrée, reportée : `AUDC-Q3` tranchée « plus tard » par Samuel le 2026-11-11** (elle rouvre « pas de terminal sur l'onglet Équipe », Q8 du 2026-11-06, les gestes réservés aux agents de la session courante, P68-D-03, et la frontière de la Phase 72, « Reprendre » sur les cartes Équipe). Inscrite le 2026-11-11 depuis l'audit du cockpit du 2026-11-10 (demande de Samuel, session principale Claude Code, 2026-11-10 ; numéro et découpage : décision déléguée par Samuel, message session principale, 2026-11-08, option recommandée).

**Goal:** Depuis la fiche d'un agent ou d'une session, ouvrir la session dans le terminal, lui écrire, demander son arrêt ou la bifurquer : chaque action prépare une commande, la touche Entrée l'exécute. Un audit de sécurité complet accompagne la phase, comme pour la 71.
**Requirements**: TBD — famille `AGIR` réservée, posée au cadrage.
**Depends on:** décision de Samuel (`AUDC-Q3`) ; Phases 71 et 72 (terminal, double geste) ; Phase 73 (régie) ; Phase 74 (fiche d'agent).
**Sources:** `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2 ; `2026-11-10-audit-cockpit/DESIGNS.md` § 5 ; registre `AUDC-I11`.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 81 to break down)
