# Roadmap: VibeFlow Dev Orchestrator (VFDO)

## Milestones

- ✅ **vfdo-v1.0** — Module dev-orchestrator (Phase 1) — clôturé 2026-06-04
- ✅ **install-ux-v1.0** — Phases 2-6 — clôturé 2026-06-05 (plugin + skill à toggles + scope) — release `v2.4.0`
- ✅ **dev-doctrine** — Phases 7-8 — doctrine dev (SOLID/DRY/KISS/YAGNI/Clean Archi/Clean Code/TDD) + consolidation des doublons qualité — clôturé 2026-07-07 — release `v2.20.0`
- ✅ **memory-swarm-rnd** — Phase 9 — R&D : transposition du modèle mémoire + patterns swarm de jcode — spike GO, shippé `v2.28.0` (ADR-052 mémoire vivante + ADR-053 swarm)
- ✅ **gsd-migration** — Phases 10-11 — clos 2026-07-26, release `v2.39.0` — migration du package GSD `get-shit-done-cc` → `@opengsd/gsd-core@^1` (VOC-02)
- ✅ **vf-routing** — Phases 12-14 — clos 2026-07-26, release `v2.37.0` — routage fin des intentions (verbes `/vf-*` à l'origine ; carte d'intention agentique depuis la bascule v2.33.0), couverture complète des skills GSD, pont spec → feuille de route, et frontière d'altitude avec le moteur de planning GSD
- ✅ **agentique-v1.0** — Phases 15→29 (18 et 25 reportées) — **clos 2026-08-15**, releases `v2.40.0` → `v2.52.0` — durcissement du moteur d'équipes agentique : collaboration inter-équipes, cloisonnement, migration `/vf-update`, alignement gsd-core, couplage et activation du moteur GSD, manuel, parallélisation, gate armement ↔ précondition (*as-installed testing*), gains ICM. **Absorbe `gsd-alignement`** (ouvert 2026-08-01 pour les phases 23-25 ; 23-24 livrées ici, 25 reportée) et solde la dérive du label `gsd-migration` resté dans STATE trois semaines après sa clôture.
- ✅ **fiabilite-v1.0** — « ce qui survit » — Phases 30-35, 37-41.4 + Phases 18 et 25 héritées — **démarré
  2026-08-15, clos 2026-10-08**, releases `v2.53.0` → `v2.69.0` (plans 41-07 à 41-13 confiés à Willy, hors clôture) — fermer les dettes de gouvernance nées d'incidents réels du milestone précédent
  (driver-lock contourné ×2, stall silencieux de 18 h, dérive du ledger re-constatée, régression
  #38) et rendre l'install/update digne de confiance sur toutes les plateformes — Windows en tête
  (demande client). Périmètre arbitré par Samuel le 2026-08-15 (familles PORT/MANI/LOCK/WTCH/LEDG/
  BUDG/WKTR/SKIL/AGTS + QUAL-01 transverse). Recherche : `.planning/research/SUMMARY.md` +
  `ARCHITECTURE.md` (ordre de construction dicté par les fichiers).
- 📋 **equipe-produit-v1.0** — « l'équipe produit : rôles humains, amont produit, état partagé » — Phases
  57-62 — **inscrit 2026-10-08**, prochain jalon exécuté (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08). Germe de `SEED-001` : ses trois déclencheurs
  sont réunis à la clôture de `fiabilite-v1.0`. Spec : `docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md`.
- 📋 **ecc-inspiration-v1.0** — « ce qu'on emprunte à ECC » — Phases 51-56 — **inscrit
  2026-09-25** — six emprunts mesurés au dépôt `affaan-m/ECC` (snapshot avant compaction,
  télémétrie d'usage et coût, apprentissage adossé à l'observation, audit du harness comme
  surface d'attaque, installeur et mémoire portables entre runtimes, packs de règles par
  langage). Étude comparative : `.planning/research/2026-09-25-ecc-inspiration-etude.md`. Jalon logé dans ce compartiment, section distincte
  dans la ROADMAP plate **sans `gsd-new-milestone`** (même forme que `gouvernance-labs-v1.0`) ;
  **exécution après la clôture de `fiabilite-v1.0`**, en parallèle du jalon de Willy
  (compartiment `gouvernance`) — arbitrage Samuel, AskUserQuestion session principale, 2026-09-25.

> **Origine des Phases 23 à 25, dite franchement.** Elles ont été inscrites au ROADMAP le
> 2026-07-31 par une session concurrente, **hors du périmètre confié** à la mission qui tournait
> alors (« fin de Phase 20 + toute la Phase 21 »), et poussées dans la PR #23 sans avoir été
> commandées. Le contenu a été jugé sérieux et **conservé** sur arbitrage de Samuel le
> 2026-08-01 ; ce jalon existe pour qu'elles cessent d'être des clandestines rattachées à
> aucun milestone. Leur ouverture reste soumise au cadrage normal (`gsd-discuss-phase`) —
> être inscrite au ROADMAP ne vaut pas feu vert d'exécution.

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
- [x] Phase 18: Survie du ledger d'exigences à la clôture de jalon (completed 2026-08-18 — 3 plans exécutés, non shippée : PR/tag/release restent des gestes humains non posés)
- [x] Phase 19: Migration du moteur GSD pilotée par /vf-update (completed 2026-07-28)
- [x] Phase 20: Fluidité du flux de dev sans perte de qualité (completed 2026-07-31)
- [x] Phase 21: Alignement du moteur GSD sur gsd-core 1.9.0 (completed 2026-07-31)
- [x] Phase 22: Hygiène documentaire — doctrine de sortie et captation d'intention (completed 2026-07-31)
- [x] Phase 23: Couplage explicite au moteur GSD — capabilities, flags et voie unique
- [x] Phase 24: Activation et mesure du moteur GSD — capacités dormantes et faits de runtime (completed 2026-08-05, PR #34)
- [x] Phase 25: Budget d'instructions (completed 2026-09-16 — ratchet armé, 31 fichiers sous contrat, conductor v1.37.1 ; seconde PR pas encore ouverte)
- [x] Phase 26: Manuel utilisateur VibeFlow (manual/) (completed 2026-08-02)
- [x] Phase 27: Parallélisation d'exécution — granulaire, simple, sans collision d'écriture (completed 2026-08-06)
- [x] Phase 28: Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur (completed 2026-08-15)
- [x] Phase 29: Distiller les gains ICM (G1-G5) — investigation dag.sh --scope d'abord (completed 2026-08-15)
- [x] Phase 30: Portabilité Windows II (completed 2026-08-16)
- [x] Phase 31: Manifeste d'install + dry-run (issue #20) (completed 2026-08-16)
- [x] Phase 32: Durcissement du driver-lock (completed 2026-08-17)
- [x] Phase 33: Watchdog & notifications des missions (completed 2026-08-17)
- [x] Phase 34: Gaps agency-agents & cadrage skill-installer (completed 2026-09-15 — 6/6 plans, mergée PR #66, AGTS-01 close, SKIL-01 NO-GO, AGTS-02 reportée avec trace ; pas de release)
- [x] Phase 35: Ré-armement worktree (conditionnelle) — CLOSE 2026-08-26, option A (pas de ré-armement)
- [x] Phase 36: RÉSERVÉ — dossier orphelin conservé, aucune exécution prévue ici (documenté 2026-09-23, contenu réel isolé sur `spike/cockpit-live`)
- [x] Phase 37: Portabilité multi-runtime — spike (Codex, OpenCode, Kimi) (completed 2026-08-28 — spike + étude livrés, décisions rendues ; suite → Phase 38)
- [x] Phase 38: Portabilité multi-runtime — livraison (canal d'install, migration de lab, adaptateur) (exécutée 2026-08-29, **mesurée 2026-08-30** sur clé API — **critère 2 PROUVÉ sur Codex** : profondeur ≥ 2 constatée EN BASE (`thread_spawn_edges`, `root→vf-dev-manager→vf-coder`), 3/3 sur les **4 critères réels** ; le **critère 5 est SANS OBJET sous clé API** (vert à vide, jamais « atteint ») et le **critère 4 est plus faible que son libellé** (`--output-schema` non propagé aux sous-agents, dette D-38-S). **kimi-code n'est plus un inconnu déclaré** : I-1 **31/31**, I-2 `disallowedTools` bloque (0/4 contre 3/3 au contrôle positif), I-3 hooks déclenchés 3/3, `vf-internal` **sans équivalent** (Pattern 12 non tenu, déclaré par le gate de fidélité). **Critère 1 toujours partiel** : hooks non portés, perte déclarée. Coûts : Codex 1,01 $, kimi ~0,018 $. **SHIPPÉE v2.59.0 le 2026-08-31** (Samuel a autorisé le ship après revue ; PR + tag + release GitHub) — test bout-en-bout install **et** usage refait sur Codex (délégation de rôle → code réel) ET Kimi (`--agent-file` → code + rapport typé) le 2026-08-31, manifeste `.codex-plugin/` natif ajouté. Preuves : `38-MESURE-CODEX-CRITERE-2.md`, `38-MESURE-KIMI.md`)
- [x] Phase 39: Workstreams — partition du planning et collaboration concurrente (cadrée 2026-09-09, exécutée 2026-09-10, 3 plans clos avec SUMMARY, revue ×3 + audit infra + juge frais sur le diff de correction ; **SHIPPÉE v2.60.0 le 2026-09-14 — PR #62** (conductor v1.35.0 : `check-divergence.sh` S2/S4/S5 + suite 17 cas dont 3 mutants, hook `post-merge` opt-in ancré sur `--git-common-dir` après RCE démontrée, étape CI ; dev-orchestrator v2.20.4 : dispatch `--ws` explicite ; `PART-01..09` gravées, `GSDA-19` superseded, ADR-069 amendé). Hotfix PR #61 regroupé dans la même release (arbitrage Samuel, AskUserQuestion session principale, 2026-09-14). **Dépôt volontairement NON partitionné** — partition réelle = geste humain séparé, déclencheur D-02 en STATE § Decisions. Réserves : premier run CI distant observé sur la PR #62 seulement ; le clone jetable prouve un mécanisme, pas un usage concurrent réel)
- [x] Phase 40: vibeflow-head — head of minds du dev-orchestrator (exécutée le 2026-09-15 sur `feat/phase-40-vibeflow-head` — `vibeflow-dev` renommé `vibeflow-head`, 5 plans/3 vagues, zéro agent neuf, kernel intact (diff nul), renommage sur 22 chemins + garde anti-alias T36 (mutation prouvée), `head-governance.md` neuf, `check-mission-exit.sh` E1-E6 codes 3/0/4/64 (23/23 cas, 6 mutations rouges), contrat de preuves E6 + ses trois émetteurs (D-19, amendement post-cadrage), racine bumpée v2.63.0, `dev-orchestrator` v2.22.0 — **PR, tag et release GitHub restent des gestes humains non posés à cette date**. **HEAD-01 partiellement close** — `intent-routing.md` jamais mis à jour pour renvoyer à `head-governance.md`, laissée ouverte au ledger, détail `40-SUMMARY.md`)
- [x] Phase 40.1: Révision ADR-029 et du gate du budget d'instructions (INSERTED 2026-09-16 — plafond 300 lignes, ratchet sur les instructions seules ; arbitrages Samuel AskUserQuestion session principale ; avant la 41)
- [x] Phase 41: Posture de protection du dépôt (**plans 41-07 à 41-13 confiés à Willy, hors clôture de `fiabilite-v1.0` — arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Les confier à Willy » pour 41-07 à 41-09, étendu à toute la chaîne (« Toute la chaîne à Willy ») ; 41-07 partiellement entamé, lignes `PR-R-*` de `41-PREUVES.md`, 2026-09-24 ; PROT-01 cochée le 2026-09-24 sur la pose des rulesets, complément attendu : la mesure du refus réel d'un push direct (41-09, complément en 41-13) est confiée à Willy** ; inscrite 2026-09-15, arbitrage Samuel AskUserQuestion session principale ; cahier des charges au BACKLOG ; séquencée après la 40 ET la calibration 25-04 ; **cadrée le 2026-09-17** — `41-CONTEXT.md`, arbitrages Samuel AskUserQuestion session principale 2026-09-17 : bypass rôle write, PR obligatoire, 4 checks requis, CODEOWNERS étroit, tags v* protégés ; critère 2 reformulé et méthodes de merge non restreintes, mêmes canal et date — **PÉRIMÈTRE RECADRÉ SANS ADMIN LIVRÉ le 2026-09-18, mergée PR #80, SHIPPÉE v2.64.0** : trois gardes in-repo qui signalent et tracent sans jamais verrouiller (G-1 `check-baseline-arbitrage.sh`, G-2 `check-gate-touche.sh`, G-3 `check-push-sans-pr.sh`) + doctrine ADR-072 ; **critères de succès 1 à 3 du ROADMAP d'origine restent HORS D'ATTEINTE sans accès admin GitHub** (au 2026-09-18 : PROT-01 non coché, `REQUIREMENTS.md` — depuis cochée le 2026-09-24) ; au 2026-09-18 : volet rulesets côté serveur **DIFFÉRÉ au BACKLOG** (rulesets posés depuis le 2026-09-23) avec son déclencheur de reprise — le compte `picmakpro` est celui de Willy, co-mainteneur du dépôt, qui a accepté de poser ce volet (WhatsApp, 2026-09-23) **avant** la clôture de `fiabilite-v1.0`, puisque PROT-01 en fait partie (correction du 2026-09-23 : la formulation précédente inversait la séquence — cf. `BACKLOG.md` § « Protection de `main` côté GitHub »))
- [x] Phase 41.1: Gates de planning workstream-aware — balayage des compartiments présents sur le disque (INSERTED 2026-09-23, demande Samuel session principale : « généralise le remède, ça ne doit plus se reproduire »)
- [x] Phase 41.2: Choisir la partition du planning au démarrage d'un lab (INSERTED 2026-09-23, demande Samuel session principale ; dépend de la 41.1 pour sa preuve d'usage) — complete 2026-10-02, mergée PR #130 ; WSCH-01 coché avec réserve : comportement de l'agent en session interactive non exercé, recette réelle au BACKLOG (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08)
- [x] Phase 41.3: Sobriété de méthode — ce qu'on crée, on le range (INSERTED 2026-09-29, arbitrage Samuel AskUserQuestion session principale ; dernière phase avant la clôture du jalon) — complete 2026-09-30
- [x] Phase 41.4: Emprunts Pocock — disciplines de cadrage, de revue et de skills (INSERTED 2026-10-06, arbitrage Samuel session principale ; demande de Willy ; dernière phase avant la clôture du jalon, après la 41.3) — complete 2026-10-06, mergée PR #135 le 2026-10-08 en `--admin`, revue `@picmakpro` contournée (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08)
- [ ] Phase 51: Snapshot de planning avant compaction (PreCompact) (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 52: Télémétrie d'usage des skills et agents, et coût de mission (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 53: Apprentissage adossé à l'observation — preuves dans la mémoire vivante (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 54: Audit du harness comme surface d'attaque (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 55: Installeur et mémoire portables entre runtimes (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 56: Packs de règles par langage (module optionnel) (inscrite 2026-09-25, jalon ecc-inspiration-v1.0)
- [ ] Phase 57: Verrou de driver par compartiment (inscrite 2026-10-08, jalon equipe-produit-v1.0)
- [ ] Phase 58: Rôles de poste — installeur, profils solo / product / dev (inscrite 2026-10-08, jalon equipe-produit-v1.0)
- [ ] Phase 59: Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate (inscrite 2026-10-08, jalon equipe-produit-v1.0)
- [ ] Phase 60: Gate architecture avant découpage et validation des phases proposées (inscrite 2026-10-08, jalon equipe-produit-v1.0)
- [ ] Phase 61: Collaboration à deux humains — divergence armée, preuve sur lab réel (inscrite 2026-10-08, jalon equipe-produit-v1.0)
- [ ] Phase 62: Décision sur l'approche plateforme, sur preuve (inscrite 2026-10-08, jalon equipe-produit-v1.0)

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ vfdo-v1.0 — Module dev-orchestrator (Phase 1) — SHIPPED 2026-06-04 -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ install-ux-v1.0 — Phases 2-6 — clôturé 2026-06-05, release `v2.4.0` -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ dev-doctrine — Phases 7-8 — clôturé 2026-07-07, release `v2.20.0` -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ memory-swarm-rnd — Phase 9 — spike GO, shippé `v2.28.0` -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ gsd-migration — Phases 10-11 — clos 2026-07-26, release `v2.39.0` -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ vf-routing — Phases 12-14 — clos 2026-07-26, release `v2.37.0` -->

## Progress

**Execution Order:**
1 ✅ → 2 ✅ → 3 ✅ → 4 ✅ → 5 ✅ ; 6 ✅ indépendant → 7 ✅ → 8 ✅ ; **9 ✅ (R&D, shippée v2.28.0)** ; **10 🚧 → 11 🚧 (GATE : 11 conditionné au GO de 10)** ; **12 ✅ → 13 ✅ (code complet, release en attente de validation humaine)** ; **14 ✅ (indépendante)** ; **15 ✅ (shippée v2.40.0) → 16 ✅ (shippée v2.41.0)** ; **17 ✅ (indépendante de 16, terminée et vérifiée — release en attente de validation humaine) → 18 inscrite (dépend de 17)** ; **19 ✅ (2026-07-28, ADR-058) → 20 ✅ (mergée dans `main` le 2026-07-31, PR #21, release `v2.44.0`)** — ce merge **satisfait** la dépendance « Phase 20 requise » de 21, 22 et 23 ; **21 ✅ (mergée le 2026-07-31, PR #22, release `v2.45.0`) + 22 ✅ (mergée le 2026-07-31, PR #23)** — les deux livrées par la mission `reprise-p21-p22`, sans fichier commun ; leur clôture **lève la dépendance** de 23 → **23 inscrite**, périmètre partagé sur `vf-dev-manager.md` / `intent-routing.md` (arbitré le 2026-07-31 : on ne planifie pas contre une base qui bouge ; l'arbitrage des étages de revue écrit par la 21 fait autorité) → **24 inscrite (dépendance doctrinale de 23, aucun fichier commun ; son lot MESURE est déjà rendu)** → **25 inscrite : après 24** (son volet G1 pose un gate sur `plugin/*/agents/*.md`, les fichiers mêmes que M3/`effort:` et A2/`agent_skills` éditent) **et dépendante de 23** (son volet G2 insère un étage dans `discuss → plan`, dont la voie unique d'invocation est arbitrée en 23) ; **milestone fiabilite-v1.0 (2026-08-15)** : **30 → 31 (strictement séquentielles — mêmes fichiers `_internal/`) → 32 → 33 (adjacentes — heartbeat partagé, WTCH après LOCK) → 18 (héritée — livrée avant clôture ; sa RFC part en Phase 30) → 34 → 25 (héritée — avant-dernière, après tout ajout d'agents)** ; **35 flottante conditionnelle** (gsd-core > 1.10.0 releasé ET installé), jamais bloquante ; **37 ✅ (spike, 2026-08-28) → 38 ✅ (shippée `v2.59.0` le 2026-08-31)** ; **39 inscrite le 2026-09-09** — aucune dépendance technique de code avec 34 ni 25, mais **condition dure ADR-069 : aucune partition tant qu'une phase est en vol** ; son rang dans la file (avant ou après 34/25) reste à trancher

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. dev-orchestrator | vfdo-v1.0 | 5/5 | Complete | 2026-06-04 |
| 2. Manifeste & résolveur | Install UX | 2/2 | Complete | 2026-06-04 |
| 3. Engine scope-aware | Install UX | 2/2 | Complete | 2026-06-05 |
| 4. Skill /vibeflow-install | Install UX | 2/2 | Complete | 2026-06-05 |
| 5. Packaging plugin | Install UX | 2/2 | Complete | 2026-06-05 |
| 6. dev-orchestrator first-use | Install UX | 1/1 | Complete | 2026-06-05 |
| 7. Philosophies de dev | dev-doctrine | 2/2 | Complete | 2026-07-07 |
| 8. Consolidation des doublons | dev-doctrine | 4/4 | Complete | 2026-07-07 |
| 9. Spike transposition jcode | memory-swarm-rnd | 2/2 | Complete — shippée `v2.28.0` (ADR-052/053) | 2026-07-22 |
| 10. Étude & faisabilité migration GSD | gsd-migration | 3/3 | Complete — GO humain validé 2026-07-26 (10-ETUDE + 10-SOLUTIONS + 10-APPROFONDISSEMENT) | 2026-07-26 |
| 11. Intégration migration GSD | gsd-migration | 6/6 | Complete — bascule @opengsd/gsd-core livrée, vérif goal-backward PASS (3/3 critères), audit sans bloquant — release `v2.39.0` | 2026-07-26 |
| 12. Routage fin & verbes /vf-* | vf-routing | 6/6 | Complete — release `v2.31.0` | 2026-07-25 |
| 13. Pont spec → feuille de route | vf-routing | 2/2 | Complete — release `v2.37.0` — module v2.2.0, vérif PASS | 2026-07-26 |
| 14. Frontière d'altitude planning-core / GSD | vf-routing | 7/7 | Complete — release `v2.30.0` (ADR-055) | 2026-07-25 |
| 15. Collaboration inter-équipes dev ↔ design | — | 7/7 | Complete — release `v2.40.0` (5/5 critères), 2 points escaladés → Phase 16 | 2026-07-27 |
| 16. Cloisonnement complet des dispatches | — | 8/8 | Complete — release `v2.41.0` (4/4 critères, SC3 amendé : contrat + lint, pas sandbox runtime) | 2026-07-27 |
| 17. Signaux de démarrage du moteur de dev | — | 3/3 | Complete — module v2.6.0, SC5/SC6 vérifiés par exécution, release racine en attente de validation humaine | 2026-07-28 |
| 18. Survie du ledger d'exigences | fiabilite-v1.0 | 3/3 | Complete — PR #51, release `v2.57.0` | 2026-08-18 |
| 19. Migration du moteur GSD par /vf-update | — | 3/3 | Complete — 3 plans exécutés, VERIFICATION produite, module `dev-orchestrator` v2.7.0 + `conductor` v1.16.0, ADR-058 | 2026-07-28 |
| 20. Fluidité du flux de dev sans perte de qualité | — | 7/7 | Complete — **mergée dans `main`** (PR #21, `d549b2d`), release `v2.44.0`, VERIFICATION produite | 2026-07-31 |
| 21. Alignement du moteur GSD sur gsd-core 1.9.0 | — | 5/5 | Complete — **mergée dans `main`** (PR #22, `d89a60e`), release `v2.45.0`, VERIFICATION produite, ADR-061/062/063 | 2026-07-31 |
| 22. Hygiène documentaire — doctrine de sortie | — | 3/3 | Complete — **mergée dans `main`** (PR #23, `474c3eb`), `dev-orchestrator` v2.9.0 + `design-orchestrator` v1.4.0 | 2026-07-31 |
| 23. Couplage explicite au moteur GSD | agentique-v1.0 | 8/8 | Complete — 8 SUMMARYs sur disque | 2026-08-04 |
| 24. Activation et mesure du moteur GSD | agentique-v1.0 | 12/12 | Complete — 12 SUMMARYs sur disque | 2026-08-04 |
| 25. Budget d'instructions | fiabilite-v1.0 | 4/4 | Complete — première PR (25-01 à 25-03) mergée v2.62.0 ; 25-04 exécutée (ratchet armé), seconde PR **mergée** (PR #73, 2026-09-16) ; rapport de sécurité suivi (PR #74) — correction du 2026-09-23, affirmation périmée | 2026-09-16 |
| 26. Manuel utilisateur VibeFlow (manual/) | gsd-alignement | — | Complete (PR #28) | 2026-08-02 |
| 27. Parallélisation d'exécution — granulaire, simple, sans collision | gsd-alignement | 6/6 | Complete (PR #35) — spike `claude_orchestration` refusé par écrit | 2026-08-10 |
| 28. Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur | agentique-v1.0 | 3/3 | Complete — PR #42, release `v2.52.0`, CI main verte, gate + `lab-frais-arme` livrés | 2026-08-15 |
| 29. Distiller les gains ICM (G1-G5) — investigation dag.sh --scope d'abord | — | 5/5 | Complete (PR #41) — release `v2.51.0`, D-03 tenue (`dag.sh` hors diff), checkpoint humain T-29-05-3 tranché le 2026-08-15 | 2026-08-15 |
| 30. Portabilité Windows II | fiabilite-v1.0 | 8/8 | Complete — PR #43, release `v2.53.0`, CI verte (run 31918283177, 4/4 jobs) | 2026-08-16 |
| 31. Manifeste d'install + dry-run (issue #20) | fiabilite-v1.0 | 8/8 | Complete — 8 SUMMARYs sur disque, module `conductor` v1.25.0, MANI-04 superseded (réponse #20 en DRAFT, jamais postée) | 2026-08-16 |
| 32. Durcissement du driver-lock | fiabilite-v1.0 | 7/7 | Complete — release `v2.55.0` (LOCK-01..05) | 2026-08-17 |
| 33. Watchdog & notifications des missions | fiabilite-v1.0 | 7/7 | Complete — release `v2.56.0` (notifications OFF par défaut, `/vf-notify`) | 2026-08-17 |
| 34. Gaps agency-agents & cadrage skill-installer | fiabilite-v1.0 | 6/6 | Complete — mergée PR #66 ; AGTS-02 reportée avec trace | 2026-09-15 |
| 35. Ré-armement worktree (conditionnelle) | fiabilite-v1.0 | — | Close — option A, pas de ré-armement (ADR-059), PR #53, release `v2.57.1` | 2026-08-26 |
| 37. Portabilité multi-runtime — spike | fiabilite-v1.0 | — | Complete — spike de mesure sans plan : DISCUSS + SPIKE-REPORT + ETUDE-CANAL-ET-MIGRATION (3 tours de revue adversariale), décisions rendues le 2026-08-28, branche `feat/phase-37-spike-portabilite-multi-runtime` non mergée | 2026-08-28 |
| 38. Portabilité multi-runtime — livraison | fiabilite-v1.0 | 8/8 | Complete — PR #56, release `v2.59.0` | 2026-08-31 |
| 39. Workstreams — partition du planning et collaboration concurrente | fiabilite-v1.0 | 3/3 | Complete — PR #62, release `v2.60.0` | 2026-09-14 |
| 40. vibeflow-head — head of minds du dev-orchestrator | fiabilite-v1.0 | 5/5 | Complete — PR #71, release `v2.63.0` (un `40-SUMMARY.md` consolidé) | 2026-09-16 |
| 40.1. Révision ADR-029 et du gate du budget d'instructions | fiabilite-v1.0 | 15/15 | Complete — PR #76, release `v2.63.2` | 2026-09-17 |
| 41. Posture de protection du dépôt | fiabilite-v1.0 | 12/19 | Complete hors 41-07 à 41-13, confiés à Willy — PR #80, release `v2.64.0` ; rulesets posés par Willy le 2026-09-23 | 2026-09-22 |
| 41.1. Gates de planning workstream-aware | fiabilite-v1.0 | 9/9 | Complete — PR #100, release `v2.66.0` | 2026-09-25 |
| 41.2. Choisir la partition du planning au démarrage d'un lab | fiabilite-v1.0 | 6/6 | Complete — PR #130, release `v2.69.0` ; WSCH-01 avec réserve (recette en session au BACKLOG) | 2026-10-02 |
| 41.3. Sobriété de méthode — ce qu'on crée, on le range | fiabilite-v1.0 | 4/4 | Complete — PR #123, release `v2.68.0` | 2026-09-30 |
| 41.4. Emprunts Pocock — disciplines de cadrage, de revue et de skills | fiabilite-v1.0 | 11/11 | Complete — PR #135 (merge `--admin`, 2026-10-08), release `v2.69.0` | 2026-10-06 |

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-09-30.md — ✅ agentique-v1.0 — Durcissement du moteur d'équipes agentique (Phases 15→29, 18 et 25 reportées) — SHIPPED 2026-08-15 -->

<!-- vf-archive: .planning/archives/roadmap/fiabilite-ROADMAP-2026-10-10.md — ✅ fiabilite-v1.0 — « ce qui survit » (Phases 30-35, 37-41.4 + 18 et 25 héritées) — SHIPPED 2026-10-08, releases `v2.53.0` → `v2.69.0` -->

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

**Milestone Goal :** emprunter à `affaan-m/ECC` (« Everything Claude Code », v2.2.2) les six
mécanismes que VibeFlow n'a pas et qui tiennent sa doctrine — observer le harness (snapshot avant
compaction, usage et coût réels, apprentissage par observation), le défendre (audit de la surface
d'attaque que sont les agents, hooks, MCP et mémoires) et le rendre portable (installeur et mémoire
entre runtimes, packs de règles par langage). Étude comparative, mesures et refus motivés :
`.planning/research/2026-09-25-ecc-inspiration-etude.md` (§1 tableau, §2 emprunts, §3 écartés, §4 collisions avec le jalon de Willy).

**Inscription :** 2026-09-25, demande de Samuel (session principale, 2026-09-25) ; jalon, nom,
compartiment et exécution différée : arbitrage Samuel, AskUserQuestion session principale, 2026-09-25. Même forme que `gouvernance-labs-v1.0` : section
distincte dans la ROADMAP plate, **sans `gsd-new-milestone`** (le STATE reste mono-position sur
`fiabilite-v1.0`, Phase 41.2 ouverte). Numéros 51-56 posés à la main (le moteur propose un mauvais
numéro sur ce dépôt ; 42-50 appartiennent au compartiment `gouvernance`).

**Exécution reportée après `equipe-produit-v1.0`** (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08, à la clôture de `fiabilite-v1.0` : les déclencheurs des
deux jalons tombaient en même temps, l'équipe produit passe d'abord). **Être inscrite
ne vaut pas feu vert** : chaque phase passe par `gsd-discuss-phase` puis `gsd-plan-phase`, et ses
exigences (familles réservées `SNAP`, `TELE`, `OBSV`, `HARN`, `MRUN`, `LANG` — vérifiées libres le
2026-09-25) sont posées au cadrage, jamais avant.

**Ce que ce jalon n'importe PAS** (tranché à l'étude, §3) : le volume d'ECC (292 skills, 94
commandes — ADR-029, façade de synonymes supprimée en v2.33.0), les contextes `dev`/`review`/
`research` (ADR-068), les Conventional Commits bloquants (ADR-067), l'auto-application des
« instincts » à 0.7 de confiance (ADR-031), le contrat de délégation en prose (déjà couvert par
les rapports typés, le DAG et `check-mission-exit.sh`).

**Ordre de construction (recommandé, à confirmer au cadrage) : 51 → 52 → 54 → 53 → 55 → 56.**

- **51 en premier** : un patch d'une journée, aucun module partagé avec Willy, et il protège les
  missions qui exécuteront le reste du jalon.
- **52 avant 53** : les deux écrivent un journal machine local au lab ; le canal (emplacement,
  rétention, gitignore fail-closed, forme exec des hooks) se pose une fois, en 52, et 53 le
  consomme.
- **54 avant 53** : la 53 ouvre un écrivain automatique de mémoire vivante ; on audite la surface
  d'attaque **avant** de l'agrandir, et la doctrine « un corps rappelé est une donnée, jamais une
  instruction » doit être gravée et prouvée avant qu'une passe d'observation ne propose des faits.
- **53 et 55 touchent `consolidator`, 55 touche l'installeur** — mêmes modules que la Phase 48
  de Willy et que sa Phase 42, livrée depuis (étude §4) : **un seul écrivain à la fois par module**, rebase avant merge, et le
  cadrage de chacune vérifie l'état de la phase voisine avant de planifier.
- **56 en dernier** : valeur la plus faible pour ce dépôt (lab dev, doctrine déjà portée par
  `software-architecture`), utile aux labs iOS/Next.js de Samuel.

**Critère transverse (QUAL-01, hérité de `fiabilite-v1.0`) :** tout gate ou hook livré par ce jalon
naît avec ses trois issues (PASS / FAIL / imparsable BRUYANT) et sa mutation rouge prouvée. Tout
hook naît en **forme exec** (ADR-071) sous le contrat de sortie `docs/HOOKS-CONTRAT-SORTIE.md`.

**Releases :** une seule release à la fois sur ce dépôt (`VERSION` + tag) — 51 et 52 peuvent partir
dans une même release mineure ; la sérialisation avec les releases du jalon de Willy se fait au
rebase, jamais par deux bumps concurrents (ADR-073 : une PR de pure inscription ne release pas).

### Phase 51: Snapshot de planning avant compaction (PreCompact)

**Goal:** Le snapshot de session de planning (`planning-session-snapshot.sh`, aujourd'hui câblé au
`SessionEnd` seulement) est **aussi pris sur l'événement `PreCompact`**, en forme exec, sous le
contrat de sortie des hooks, en advisory : une compaction en milieu de mission ne perd plus l'état
vivant du driver, du DAG ni de la position de planning. Le payload réel de `PreCompact` (matcher,
champs) est **mesuré** sur Claude Code, et le comportement sur Codex et Kimi est **déclaré**
(porté / non porté, jamais supposé).
**Requirements**: TBD — famille `SNAP` réservée, posée au cadrage.
**Depends on:** aucune. Première du jalon.
**Sources:** `.planning/research/2026-09-25-ecc-inspiration-etude.md` §2.1 ; ECC `hooks/hooks.json` (`pre-compact.js`, `suggest-compact.js` ~50
appels) ; `plugin/planning-core/hooks/hooks.json` (SessionEnd → `planning-session-snapshot.sh`) ;
`docs/HOOKS-CONTRAT-SORTIE.md` ; ADR-071.
**Hors périmètre :** un rappel « /compact suggéré tous les N appels » — l'autocompact du runtime
existe ; à ne rouvrir que sur un incident mesuré.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 51 to break down)

### Phase 52: Télémétrie d'usage des skills et agents, et coût de mission

**Goal:** Un journal machine, **local au lab et gitignoré fail-closed**, enregistre ce qui est
réellement invoqué (skill, agent, modèle, durée, issue, tokens **si le runtime les expose — sinon
« inconnu », jamais estimé**), posé par hook au `Stop`/`SessionEnd` et relevé à la sortie de
mission ; `check-overlaps.sh` et l'audit de densité du validator **consomment** ces relevés, si
bien que la prochaine décision de retrait d'un agent ou d'un skill s'appuie sur un usage mesuré et
non sur un avis. Le head « compte ce que coûtent les équipes » sur une donnée, pas sur une phrase.
**Requirements**: TBD — famille `TELE` réservée, posée au cadrage.
**Depends on:** aucune dépendance de code ; après 51 par ordre de valeur.
**Sources:** `.planning/research/2026-09-25-ecc-inspiration-etude.md` §2.2 ; ECC `skill-run-tracker.js`, `cost-tracker.js`, `evaluate-session.js`
(hooks `Stop`/`PostToolUseFailure`) ; `plugin/conductor/scripts/check-overlaps.sh` ;
`head-governance.md` (le head compte les coûts) ; doctrine `kpi-analyst` (aucun chiffre inventé).
**Garde-fous :** rien ne sort du poste (pas de télémétrie distante) ; le journal est borné en
taille et en rétention ; une métrique non exposée est « inconnue ».
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 52 to break down)

### Phase 53: Apprentissage adossé à l'observation — preuves dans la mémoire vivante

**Goal:** Un journal d'observations **déterministe** (hook `PostToolUse`, JSONL local, gitignoré,
borné) alimente une passe d'analyse (agent observateur sur modèle léger) qui **propose** — jamais
n'applique — des faits de mémoire vivante avec leurs preuves (observations citées) ; le champ
`confidence` d'ADR-052 est alimenté par des preuves observées plutôt que déclaré ; la promotion
learning → rule est proposée sur **récurrence constatée dans au moins deux labs** ; toute écriture
reste soumise à validation humaine (ADR-031). Les registres tabulaires d'audit restent inchangés
(ADR-052, deux systèmes distincts).
**Requirements**: TBD — famille `OBSV` réservée, posée au cadrage.
**Depends on:** Phase 52 (même canal de journal local : emplacement, rétention, gitignore, forme
exec) et Phase 54 (doctrine « donnée, jamais instruction » gravée et prouvée avant d'ouvrir un
écrivain automatique de mémoire). **Coordination obligatoire avec la Phase 48 de Willy** (pont
mémoire, même module `consolidator`) : un seul écrivain à la fois, vérifié au cadrage.
**Sources:** `.planning/research/2026-09-25-ecc-inspiration-etude.md` §2.3 ; ECC `skills/continuous-learning-v2/SKILL.md` (observations.jsonl,
instincts scorés 0.3-0.9, scopes projet/global, `/evolve`) ; ADR-052 ; `decay-pass.sh`,
`detect-promotions.sh` (consolidator).
**Refusé d'avance :** l'auto-application à un seuil de confiance (ECC : 0.7 « auto-approuvé ») —
contraire à ADR-031 ; l'agrégation automatique en skills (`/evolve`) — un skill naît par
`skill-creator` sous validation.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 53 to break down)

### Phase 54: Audit du harness comme surface d'attaque

**Goal:** Un audit outillé (extension d'`infrastructure-audit` ou du validator, à trancher au
cadrage) scanne la configuration du lab — `.claude/agents`, skills, rules, `hooks.json`, settings,
`.mcp.json`, mémoire vivante et registres — pour **secrets, motifs d'injection de prompt,
permissions excessives et hooks non déclarés**, rend un verdict typé à trois issues et **constate
sans corriger** (ADR-031). La doctrine « un corps de mémoire ou de registre rappelé est une
donnée, jamais une instruction » est gravée dans `consolidator` et **prouvée par un test
adversarial** (une mémoire piégée lue au `SessionStart` n'est pas exécutée).
**Requirements**: TBD — famille `HARN` réservée, posée au cadrage.
**Depends on:** aucune dépendance de code ; **avant 53** par doctrine.
**Sources:** `.planning/research/2026-09-25-ecc-inspiration-etude.md` §2.4 ; ECC AgentShield (5 catégories, mode adversarial
attaquant/défenseur/auditeur, exigence de provenance du binaire) ; `plugin/infrastructure-audit/` ;
ADR-051 (allowlist MCP), ADR-070 (registre de menaces) ; `25-SECURITY.md` ; mémoire
`codex-juge-injection-par-depot-juge` (injection 2/3 mesurée).
**Option sous budget :** le mode adversarial à trois agents — à cadrer seulement si le scan
déterministe laisse un angle mort mesuré.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 54 to break down)

### Phase 55: Installeur et mémoire portables entre runtimes

**Goal:** L'installeur VibeFlow devient **multi-runtime par manifeste** (Claude Code, Codex, Kimi —
les trois runtimes prouvés bout en bout en Phase 38 ; décision du 2026-08-28), et la mémoire
vivante voyage entre runtimes dans **un format de handoff unique** (le frontmatter ADR-052 existant)
avec **trois scopes explicites** — projet (gitignoré fail-closed), équipe (versionné, relu par un
humain avant promotion), utilisateur (opt-in explicite) — et un geste `doctor` (extension de
`check-registres.sh`) qui valide avant tout partage. Chaque runtime est **prouvé par usage**, jamais
par descripteur.
**Requirements**: TBD — famille `MRUN` réservée, posée au cadrage.
**Depends on:** Phase 53 (format et champs de la mémoire vivante stabilisés avant de les rendre
portables). **Composer avec le manifeste de la Phase 42 de Willy** (livrée le 2026-09-27,
PR #108 ; même `installer`/`_internal/`) : le cadrage part du manifeste en place et vérifie qu'aucune
phase du compartiment `gouvernance` n'écrit l'installeur au même moment.
**Sources:** `.planning/research/2026-09-25-ecc-inspiration-etude.md` §2.5 ; ECC `ecc-universal setup` (manifeste), vault `ecc.memory.v1`, scopes et
`memory doctor` ; mémoires `agent-skills-ecarte-superpowers-reste` (installeur multi-runtime décidé
2026-08-28), `memoire-per-projet-scope-user`, `phase-37-et-38-portabilite` ; ADR-052.
**Refusé d'avance :** les adaptateurs « expérimentaux/minimaux » (Cursor, Gemini, Zed…) — un
descripteur n'est pas une preuve (Phases 37-38).
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 55 to break down)

### Phase 56: Packs de règles par langage (module optionnel)

**Goal:** Un module **toggable** (nom à trancher au cadrage, par exemple `lang-rules`) livre des
rules path-scopées par stack — Swift et TypeScript/Next.js d'abord, selon les labs réels — et des
hooks `Stop` **opt-in** (typecheck et format sur les fichiers édités) en forme exec ; rien n'est
chargé sur un lab qui n'a pas la stack (détection, pas déclaration) ; l'opinion ECC est **filtrée**
(pas de seuil de couverture imposé, pas de Conventional Commits — ADR-067) ; la densité ADR-029
s'applique aux rules comme aux agents.
**Requirements**: TBD — famille `LANG` réservée, posée au cadrage.
**Depends on:** aucune dépendance de code ; dernière du jalon par ordre de valeur.
**Sources:** `.planning/research/2026-09-25-ecc-inspiration-etude.md` §2.6 ; ECC `rules/common/` (10 fichiers) + packs `typescript/`, `python/`,
`golang/`, `swift/` ; hooks `stop-format-typecheck.js`, `check-console-log.js` ;
`plugin/software-architecture/rules/`, `plugin/mobile-test-team/rules/` (précédents de rules
path-scopées) ; ADR-029, ADR-067.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 56 to break down)

## 📋 Milestone equipe-produit-v1.0 — « l'équipe produit » (Phases 57-62)

**Milestone Goal :** VibeFlow sert une **équipe** et plus seulement un humain qui a tous les modules. Il apporte des
rôles de poste (solo par défaut, product, dev), des artefacts amont lisibles par un non-dev, et un état partagé entre
clones, sans recréer de couche de personas synonymes. Un rôle est **une vue, pas un droit** : git ne tient aucun
cloisonnement humain, et la doc le dit dès sa première ligne. Spec :
`docs/superpowers/specs/2026-09-16-equipe-produit-bmad-design.md`. Germe : `.planning/seeds/SEED-001-equipe-produit-v1.md`,
dont les douze arbitrages A-01 à A-12 du 2026-09-16 tiennent, sauf A-09 (révisé ci-dessous). Doctrine :
`.planning/notes/2026-09-16-doctrine-agentique-ouverte-collaboration-humaine.md`.

**Inscription :** 2026-10-08, à la clôture de `fiabilite-v1.0`. Choix de ce jalon avant `ecc-inspiration-v1.0`, forme
d'inscription et place du verrou : arbitrage Samuel, AskUserQuestion session principale, 2026-10-08. Même forme qu'ECC et `gouvernance-labs-v1.0` : section distincte de la
ROADMAP plate, **sans `gsd-new-milestone`**. Les numéros 57 à 62 sont posés à la main (42-50 : compartiment
`gouvernance` ; 51-56 : ECC).

**Révision d'A-09, tracée.** La SEED supposait le verrou de driver par compartiment livré « avant, dans D-02 ». La
mission D-02 du 2026-09-23 n'a fait que la partition. Mesuré le 2026-10-08 : `driver-lock.sh` ne connaît aucun
workstream, et ADR-053 n'a reçu aucun amendement. Le verrou devient donc la **première phase du jalon** (57) ; c'est
une précondition dure de la collaboration à deux humains (61) (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08).

**Être inscrite ne vaut pas feu vert.** Chaque phase passe par `gsd-discuss-phase` puis `gsd-plan-phase`. Ses exigences
sont posées au cadrage, jamais avant, dans les familles réservées et vérifiées libres le 2026-10-08 : `DLWS` (57),
`RLPO` (58), `PRDT` (59), `ARCG` (60), `COLB` (61), `PLTF` (62). `ROLE` était déjà pris, 41 occurrences.

**Critères de succès du jalon** (spec §9) :
1. Une install `VF_ROLE=product` n'expose aucune commande dev et pose `conductor` et `consolidator`.
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

**Goal:** `driver-lock.sh` devient compartiment-aware : un verrou nommé par workstream, et un amendement daté d'ADR-053 change l'invariant en « un manager **par compartiment** ». `guard-driver-lock.sh` est aligné. Le head passe `--ws` et un `GSD_SESSION_KEY` distinct **par manager**. Un lab non partitionné garde exactement le comportement d'aujourd'hui.
**Requirements**: DLWS-01 à DLWS-08
**Depends on:** aucune. Première du jalon.
**Sources:** spec head `docs/superpowers/specs/2026-09-15-vibeflow-head-design.md` §6, points (1) à (3) ; ADR-053 ; `plugin/conductor/scripts/driver-lock.sh` et `guard-driver-lock.sh` ; BACKLOG « guard-driver-lock.sh sous EnterWorktree vise le checkout principal ».
**Hors périmètre :** la preuve d'usage concurrent réel (§6, point 4), portée par la Phase 61.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 57 to break down)

### Phase 58: Rôles de poste — installeur, profils solo / product / dev

**Goal:** `/vibeflow-install` demande le rôle sur ce projet, pré-coché « solo », avec un mode non interactif par `VF_ROLE`. `module.json` porte `roles` (absent = tous), et `build-module-catalog.sh` filtre le catalogue. Le rôle vit dans un fichier local non versionné (A-11) ; le projet ne porte que la liste des rôles autorisés, vérifiée par `check-role-consistency.sh`. Trois profils seulement (A-02).
**Requirements**: TBD — famille `RLPO` réservée, posée au cadrage.
**Depends on:** 57.
**Sources:** spec §5.1, §5.4 ; SEED A-02, A-04, A-11 ; `plugin/installer/`, `plugin/_internal/vibeflow-update.sh`.
**Hors périmètre :** les rôles architecte, QA et scrum master (A-02) ; tout contrôle d'accès.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 58 to break down)

### Phase 59: Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate

**Goal:** Un bundle produit sur le moule de `business-pilot-bundle`. La front door `vibeflow-product`, sur le moule de `vibeflow-design`, produit `BRIEF.md` (le seul fichier nouveau, A-06) et le PRD (`PROJECT.md` + `REQUIREMENTS.md`, gabarit `product` de `planning-core`). Un juge frais `prd-gate`, en lecture seule et sur rubric /100, rend éliminatoire toute exigence sans critère d'acceptation. `vibeflow-head` lit le rôle pour rediriger au lieu de dispatcher `vf-coder` (A-05). Le bundle reste `proposable: false` jusqu'à preuve sur un lab réel (Q-09, défaut probable).
**Requirements**: TBD — famille `PRDT` réservée, posée au cadrage.
**Depends on:** 58.
**Sources:** spec §5.2 ; SEED A-05, A-06, A-10 (vocabulaire : on garde l'existant, aucun renommage) ; `plugin/business-pilot-bundle/`, `plugin/design-orchestrator/`.
**Hors périmètre :** un fichier PRD.md séparé (A-06) ; les termes « epic » et « story » (Q-11, fermée par doctrine).
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 59 to break down)

### Phase 60: Gate architecture avant découpage et validation des phases proposées

**Goal:** Un gate séparé assemble l'existant : `software-architecture` et GSD (`gsd-map-codebase`, `gsd-graphify`). Le head refuse le découpage en phases tant que `ARCHITECTURE.md` n'est pas validée (A-08). Une phase ajoutée par le rôle product ou par le head reste **proposée** jusqu'à sa validation par un dev ; en solo, elle est auto-validée. Le mécanisme passe par un marqueur sur la phase et `check-phase-validation.sh` (A-07).
**Requirements**: TBD — famille `ARCG` réservée, posée au cadrage.
**Depends on:** 59.
**Sources:** spec §5.2 ; SEED A-07, A-08 ; `plugin/software-architecture/`, `plugin/audit-architecture/`.
**Hors périmètre :** un gate bloquant sans halt condition (Q-04 : ADR-031 penche pour l'advisory).
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 60 to break down)

### Phase 61: Collaboration à deux humains — divergence armée, preuve sur lab réel

**Goal:** Pour un lab multi-humains, `check-divergence.sh` et son hook `post-merge` sont armés par défaut. Le champ `role:` s'ajoute aux entrées des registres (DECISIONS, LEARNINGS, BLOCKERS). La preuve est faite à **deux humains, deux clones, deux rôles, un workstream** sur un lab réel, pas sur un clone jetable (spec §9, critère 4 ; spec head §6, point 4).
**Requirements**: TBD — famille `COLB` réservée, posée au cadrage.
**Depends on:** 57 et 60.
**Sources:** spec §5.3 ; Phase 39 (`check-divergence.sh`) ; ADR-069.
**Hors périmètre :** un workstream par rôle (deux vérités, refusé par la spec §5.3).
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 61 to break down)

### Phase 62: Décision sur l'approche plateforme, sur preuve

**Goal:** Une décision écrite sur l'approche C de la spec (plateforme collaborative : hub, base centrale), prise sur mesure : le besoin non-dev sans terminal est-il réel (Q-06) ? À défaut de preuve, le jalon se clôt sur un déclencheur daté de reprise. Aucun code avant la décision.
**Requirements**: TBD — famille `PLTF` réservée, posée au cadrage.
**Depends on:** 61.
**Sources:** spec §4 C, §7 Q-05/Q-06.
**Hors périmètre :** toute implémentation de plateforme.
**Plans:** 0 plans

Plans:

- [ ] TBD (run /gsd-plan-phase 62 to break down)
