<!-- archive du tri de 2026-11-05 : texte d'origine retiré du ROADMAP du compartiment fiabilite, tel qu'il était au blob f909d1d5ef98e47201be57d7319230fa1909799f (restituable par git cat-file blob f909d1d5ef98e47201be57d7319230fa1909799f) ; chaque marqueur « archive : » donne la section d'origine et sa ligne dans ce blob -->

<!-- archive : entrée Milestones agentique-v1.0 (source l.11) -->
- ✅ **agentique-v1.0** — Phases 15→29 (18 et 25 reportées) — **clos 2026-08-15**, releases `v2.40.0` → `v2.52.0` — durcissement du moteur d'équipes agentique : collaboration inter-équipes, cloisonnement, migration `/vf-update`, alignement gsd-core, couplage et activation du moteur GSD, manuel, parallélisation, gate armement ↔ précondition (*as-installed testing*), gains ICM. **Absorbe `gsd-alignement`** (ouvert 2026-08-01 pour les phases 23-25 ; 23-24 livrées ici, 25 reportée) et solde la dérive du label `gsd-migration` resté dans STATE trois semaines après sa clôture.
<!-- archive : entrée Milestones fiabilite-v1.0 (source l.12) -->
- ✅ **fiabilite-v1.0** — « ce qui survit » — Phases 30-35, 37-41.4 + Phases 18 et 25 héritées — **démarré
  2026-08-15, clos 2026-10-08**, releases `v2.53.0` → `v2.69.0` (plans 41-07 à 41-13 confiés à Willy, hors clôture) — fermer les dettes de gouvernance nées d'incidents réels du milestone précédent
  (driver-lock contourné ×2, stall silencieux de 18 h, dérive du ledger re-constatée, régression
  #38) et rendre l'install/update digne de confiance sur toutes les plateformes — Windows en tête
  (demande client). Périmètre arbitré par Samuel le 2026-08-15 (familles PORT/MANI/LOCK/WTCH/LEDG/
  BUDG/WKTR/SKIL/AGTS + QUAL-01 transverse). Recherche : `.planning/research/SUMMARY.md` +
  `ARCHITECTURE.md` (ordre de construction dicté par les fichiers).
<!-- archive : Origine des Phases 23 à 25 (source l.40) -->
> **Origine des Phases 23 à 25, dite franchement.** Elles ont été inscrites au ROADMAP le
> 2026-07-31 par une session concurrente, **hors du périmètre confié** à la mission qui tournait
> alors (« fin de Phase 20 + toute la Phase 21 »), et poussées dans la PR #23 sans avoir été
> commandées. Le contenu a été jugé sérieux et **conservé** sur arbitrage de Samuel le
> 2026-08-01 ; ce jalon existe pour qu'elles cessent d'être des clandestines rattachées à
> aucun milestone. Leur ouverture reste soumise au cadrage normal (`gsd-discuss-phase`) —
> être inscrite au ROADMAP ne vaut pas feu vert d'exécution.
<!-- archive : checklist des Phases <= 41.4 (lignes d'origine ; remplacées par une forme courte) (source l.64) -->
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
- [x] Phase 41.1: Gates de planning workstream-aware — balayage des compartiments présents sur le disque (INSERTED 2026-09-23, demande Samuel session principale : « généralise le remède, ça ne doit plus se reproduire »)
- [x] Phase 41.2: Choisir la partition du planning au démarrage d'un lab (INSERTED 2026-09-23, demande Samuel session principale ; dépend de la 41.1 pour sa preuve d'usage) — complete 2026-10-02, mergée PR #130 ; WSCH-01 coché avec réserve : comportement de l'agent en session interactive non exercé, recette réelle au BACKLOG (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08)
- [x] Phase 41.3: Sobriété de méthode — ce qu'on crée, on le range (INSERTED 2026-09-29, arbitrage Samuel AskUserQuestion session principale ; dernière phase avant la clôture du jalon) — complete 2026-09-30
- [x] Phase 41.4: Emprunts Pocock — disciplines de cadrage, de revue et de skills (INSERTED 2026-10-06, arbitrage Samuel session principale ; demande de Willy ; dernière phase avant la clôture du jalon, après la 41.3) — complete 2026-10-06, mergée PR #135 le 2026-10-08 en `--admin`, revue `@picmakpro` contournée (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08)
<!-- archive : checklist des Phases 57-62, 67 et 69 (lignes d'origine) (source l.116) -->
- [x] Phase 57: Verrou de driver par compartiment (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-12, mergée PR #152 le 2026-10-16 en `--admin`, revue `@picmakpro` contournée (demande explicite de Samuel, session principale Claude Code, 2026-10-16 : « merge sans willy, release + tag »), release `v2.70.0` ; 16/16 plans, DLWS-01..08 cochées
- [x] Phase 58: Rôles de poste — installeur, profils solo / product / dev (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-22 : 12/12 plans, porte de phase verte, RLPO-01..12 cochées dont RLPO-11 par override (critère 6 et recette installeur non mesurés, Samuel, session principale, 2026-10-22 — dette dans 58-VERIFICATION.md), branche rebasée sur v2.70.1, release `v2.71.0` à venir
- [x] Phase 59: Bundle produit — front door vibeflow-product, BRIEF et juge prd-gate (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-27 : 8/8 plans, porte de phase verte, PRDT-01..12 cochées, livrée en `v2.73.0`
- [x] Phase 60: Gate architecture avant découpage et validation des phases proposées (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-29 : 9/9 plans, porte de phase verte (job `gates` rejoué depuis `ci.yml`, suites une à une), ARCG-02..08, 10 et 11 cochées, ARCG-01 partielle (dette : pose à la création non prouvée par une exécution), ARCG-09 partielle (critère 6 `clients` en code 2, en attente de la liste), livrée en `v2.74.0`
- [x] Phase 61: Collaboration à deux humains — divergence armée, preuve sur lab réel (inscrite 2026-10-08, jalon equipe-produit-v1.0) — complete 2026-10-29 : 8/8 plans, porte de phase verte (job `gates` rejoué depuis `ci.yml`, suites une à une), COLB-01..07 cochées, COLB-09 partielle (critère 6 `clients` en code 2), COLB-08 en attente de la preuve humaine (P61-B-01, P61-B-02), livrée en `v2.74.0`
- [x] Phase 62: Décision sur l'approche plateforme, sur preuve (inscrite 2026-10-08, jalon equipe-produit-v1.0) — close 2026-10-29 : décision A (approche C différée), réexamen 2027-01-31, PLTF-01..02 cochées (aucune release : ADR-073)
- [x] Phase 67: Cockpit floorplan sur socle partagé (inscrite 2026-11-01, jalon vibeflow-v2.0) — complete 2026-11-03 : 7/7 plans et 4 tours de correction (FIX-A à FIX-D), recette humaine validée par Samuel (`67-RECETTE-HUMAINE.md` § 8.2), CKPT-01..12 cochées ; release `v2.75.0` préparée (tag et release GitHub après le merge de la PR #187, geste de Samuel)
- [x] Phase 69: Suivi du travail en cours dans le cockpit (inscrite 2026-11-03, jalon vibeflow-v2.0) — complete 2026-11-04 : 9/9 plans, recette déroulée par juges Playwright (arbitrage de méthode de Samuel, session principale Claude Code, 2026-11-04), 4 écarts corrigés, CKPT-13..28 cochées, vérification 16/16 (`69-VERIFICATION.md`) ; PR #198, sans release (P69-D-29)
<!-- archive : Execution Order (source l.147) -->
**Execution Order:**
1 ✅ → 2 ✅ → 3 ✅ → 4 ✅ → 5 ✅ ; 6 ✅ indépendant → 7 ✅ → 8 ✅ ; **9 ✅ (R&D, shippée v2.28.0)** ; **10 🚧 → 11 🚧 (GATE : 11 conditionné au GO de 10)** ; **12 ✅ → 13 ✅ (code complet, release en attente de validation humaine)** ; **14 ✅ (indépendante)** ; **15 ✅ (shippée v2.40.0) → 16 ✅ (shippée v2.41.0)** ; **17 ✅ (indépendante de 16, terminée et vérifiée — release en attente de validation humaine) → 18 inscrite (dépend de 17)** ; **19 ✅ (2026-07-28, ADR-058) → 20 ✅ (mergée dans `main` le 2026-07-31, PR #21, release `v2.44.0`)** — ce merge **satisfait** la dépendance « Phase 20 requise » de 21, 22 et 23 ; **21 ✅ (mergée le 2026-07-31, PR #22, release `v2.45.0`) + 22 ✅ (mergée le 2026-07-31, PR #23)** — les deux livrées par la mission `reprise-p21-p22`, sans fichier commun ; leur clôture **lève la dépendance** de 23 → **23 inscrite**, périmètre partagé sur `vf-dev-manager.md` / `intent-routing.md` (arbitré le 2026-07-31 : on ne planifie pas contre une base qui bouge ; l'arbitrage des étages de revue écrit par la 21 fait autorité) → **24 inscrite (dépendance doctrinale de 23, aucun fichier commun ; son lot MESURE est déjà rendu)** → **25 inscrite : après 24** (son volet G1 pose un gate sur `plugin/*/agents/*.md`, les fichiers mêmes que M3/`effort:` et A2/`agent_skills` éditent) **et dépendante de 23** (son volet G2 insère un étage dans `discuss → plan`, dont la voie unique d'invocation est arbitrée en 23) ; **milestone fiabilite-v1.0 (2026-08-15)** : **30 → 31 (strictement séquentielles — mêmes fichiers `_internal/`) → 32 → 33 (adjacentes — heartbeat partagé, WTCH après LOCK) → 18 (héritée — livrée avant clôture ; sa RFC part en Phase 30) → 34 → 25 (héritée — avant-dernière, après tout ajout d'agents)** ; **35 flottante conditionnelle** (gsd-core > 1.10.0 releasé ET installé), jamais bloquante ; **37 ✅ (spike, 2026-08-28) → 38 ✅ (shippée `v2.59.0` le 2026-08-31)** ; **39 inscrite le 2026-09-09** — aucune dépendance technique de code avec 34 ni 25, mais **condition dure ADR-069 : aucune partition tant qu'une phase est en vol** ; son rang dans la file (avant ou après 34/25) reste à trancher
<!-- archive : table Progress, lignes des Phases <= 41.4 (copie aussi dans .planning/milestones/fiabilite-v1.0-ROADMAP.md) (source l.152) -->
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
| 41.1. Gates de planning workstream-aware | fiabilite-v1.0 | 9/9 | Complete — PR #100, release `v2.66.0` | 2026-09-25 |
| 41.2. Choisir la partition du planning au démarrage d'un lab | fiabilite-v1.0 | 6/6 | Complete — PR #130, release `v2.69.0` ; WSCH-01 avec réserve (recette en session au BACKLOG) | 2026-10-02 |
| 41.3. Sobriété de méthode — ce qu'on crée, on le range | fiabilite-v1.0 | 4/4 | Complete — PR #123, release `v2.68.0` | 2026-09-30 |
| 41.4. Emprunts Pocock — disciplines de cadrage, de revue et de skills | fiabilite-v1.0 | 11/11 | Complete — PR #135 (merge `--admin`, 2026-10-08), release `v2.69.0` | 2026-10-06 |
<!-- archive : jalon ecc-inspiration-v1.0, intro et Phases 51 à 56 (source l.321) -->
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

<!-- archive : fin du jalon ecc-inspiration-v1.0 (source l.508) -->
<!-- archive : intro equipe-produit-v1.0, paragraphes Inscription et Révision d A-09 (source l.518) -->
**Inscription :** 2026-10-08, à la clôture de `fiabilite-v1.0`. Choix de ce jalon avant `ecc-inspiration-v1.0`, forme
d'inscription et place du verrou : arbitrage Samuel, AskUserQuestion session principale, 2026-10-08. Même forme qu'ECC et `gouvernance-labs-v1.0` : section distincte de la
ROADMAP plate, **sans `gsd-new-milestone`**. Les numéros 57 à 62 sont posés à la main (42-50 : compartiment
`gouvernance` ; 51-56 : ECC). La Phase 63 est ajoutée le 2026-10-29 par `gsd-phase` (arbitrage Samuel, AskUserQuestion
session principale, 2026-10-29 : « phase dans le jalon actuel », règles AIDD dans notre vocabulaire). Les Phases
64 et 65 sont ajoutées le même jour par `gsd-phase` (arbitrage Samuel, message session principale, 2026-10-29) ; elles
portent sur le flux des agents de dev, pas sur l'équipe produit, et peuvent glisser au jalon suivant à la clôture.

<!-- archive : intro equipe-produit-v1.0, paragraphes Inscription et Révision d A-09 (source l.526) -->
**Révision d'A-09, tracée.** La SEED supposait le verrou de driver par compartiment livré « avant, dans D-02 ». La
mission D-02 du 2026-09-23 n'a fait que la partition. Mesuré le 2026-10-08 : `driver-lock.sh` ne connaît aucun
workstream, et ADR-053 n'a reçu aucun amendement. Le verrou devient donc la **première phase du jalon** (57) ; c'est
une précondition dure de la collaboration à deux humains (61) (arbitrage Samuel, AskUserQuestion session principale, 2026-10-08).

<!-- archive : Phase 57 (corps) (source l.557) -->

**Sources:** spec head `docs/superpowers/specs/2026-09-15-vibeflow-head-design.md` §6, points (1) à (3) ; ADR-053 ; `plugin/conductor/scripts/driver-lock.sh` et `guard-driver-lock.sh` ; BACKLOG « guard-driver-lock.sh sous EnterWorktree vise le checkout principal ».
**Hors périmètre :** la preuve d'usage concurrent réel (§6, point 4), portée par la Phase 61.
**Plans:** 16/16 plans exécutés en 10 vagues (2026-10-12) ; mergée PR #152 le 2026-10-16, release `v2.70.0`

Plans:
**Wave 1**
- [x] 57-01-PLAN.md — vague 1 : `driver-lock.sh`, verrou d'un compartiment, verrou de dépôt, refus nommés (contrat de la phase), suite `test-driver-lock-ws.sh`

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 57-02-PLAN.md — vague 2 : `driver-lock.sh`, ancien verrou à la mise à jour, partage entre worktrees, repli hors git, mode verrou unique

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 57-03-PLAN.md — vague 3 : `driver-lock.sh`, `status --all`, `--ws` sur tous les verbes, registre par verrou

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 57-04-PLAN.md — vague 4 : preuves de `driver-lock.sh` (concurrence 24×5, A/B lab plat contre copie gelée, mutants DL-M-*)
- [x] 57-05-PLAN.md — vague 4 : `guard-driver-lock.sh`, écritures par compartiment, découverte des verrous, fail-closed dès l'aiguillage, quatre issues, suite `test-guard-driver-lock-ws.sh`
- [x] 57-06-PLAN.md — vague 4 : consommateurs de progrès (watchdog `status --all`, `dag.sh init --ws`), suite `test-driver-lock-consumers-ws.sh`
- [x] 57-07-PLAN.md — vague 4 : gate de sortie `check-mission-exit.sh --ws` (E1, identité d'E7, surcharge d'E4), suite `test-check-mission-exit-ws.sh`

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 57-08-PLAN.md — vague 5 : `guard-driver-lock.sh`, jugement de commit sur l'union des sources, trois classes de gestes git
- [x] 57-09-PLAN.md — vague 5 : claim de branche sur les verrous du clone, bilan 7/7 des mutants des consommateurs
- [x] 57-10-PLAN.md — vague 5 : doctrine dev-orchestrator (mission-flow, vf-dev-manager, workers, head-governance, intent-routing, mission-cross-team)

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 57-11-PLAN.md — vague 6 : preuves du guard (A/B lab plat contre copie gelée, mutants GW-M-*, latence)
- [x] 57-12-PLAN.md — vague 6 : team-kernel, managers design et bundles, skill `vf-split-planning` sous verrou de dépôt

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 57-13-PLAN.md — vague 7 : amendement daté d'ADR-053, spec head §6, contrat des hooks, étape de release de `CLAUDE.md` en deux gestes de dépôt courts, manuel FR+EN

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 57-14-PLAN.md — vague 8 : bumps de cinq modules sans release (conductor, dev-orchestrator, design-orchestrator, business-pilot-bundle, content-bundle)

**Wave 9** *(blocked on Wave 8 completion)*
- [x] 57-15-PLAN.md — vague 9 : bump de growth-bundle, compte de suites des README racine, BACKLOG réécrit

**Wave 10** *(blocked on Wave 9 completion)*
- [x] 57-16-PLAN.md — vague 10 : porte de phase rejouée depuis `ci.yml`, puis ledger à la main

<!-- archive : Phase 58 (corps) (source l.603) -->

**Sources:** spec §5.1, §5.4 ; SEED A-02, A-04, A-11 ; `plugin/installer/`, `plugin/_internal/vibeflow-update.sh`.
**Hors périmètre :** les rôles architecte, QA et scrum master (A-02) ; tout contrôle d'accès.
**Plans:** 12 plans

Plans:

**Wave 1**
- [x] 58-01-PLAN.md — vague 1 : clé `roles` des `module.json`, validateur unique `module-roles.sh`, table minimale (3 modules `["dev"]`), invariant de fermeture `product` ; contrat de phase et registre P58-PL-01..14
- [x] 58-02-PLAN.md — vague 1 : lecteur unique du poste `vf-role.sh get` (interface des Phases 59 à 61), suite à mutants
- [x] 58-03-PLAN.md — vague 1 : ADR-077 sous verrou de dépôt court du manager, relue par Samuel (non autonome)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 58-04-PLAN.md — vague 2 : gate `check-role-consistency.sh` (0/1/3/5), ligne « Poste : X » au SessionStart, entrée de hook exec, inventaire des hooks à 32
- [x] 58-05-PLAN.md — vague 2 : catalogue filtré par `--role`/`VF_ROLE`, sortie sans poste identique à l'octet (copie gelée)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 58-06-PLAN.md — vague 3 : engine, volet pose — `--role`/`VF_ROLE`, fichier de poste, règle d'ignorance séparée, `.worktreeinclude` conditionnel, refus à la pose, arêtes de scope
- [x] 58-07-PLAN.md — vague 3 : skill installeur (étape 2 bis, repli sans fuite, note des bundles, « statut »), glossaire, README de conductor

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 58-08-PLAN.md — vague 4 : engine, volet usage — filtre de `install --all`, registre et `update --all` intacts, verbe `role` et avis

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 58-09-PLAN.md — vague 5 : suite e2e des critères 1, 2 et 5, outil de livraison (`base`, `gitignore-intact`, `fichiers-intacts`, `clients`)
- [x] 58-10-PLAN.md — vague 5 : bumps sans release (conductor v1.50.0, dev-orchestrator v2.28.1, mobile-test v1.0.4, mobile-test-team v1.4.7)

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 58-12-PLAN.md — vague 6 : presets filtrés par poste (`resolve-preset.sh list --role`, fermeture de dépendances), sortie sans poste identique à l'octet, suite à mutants, ligne du skill installeur (P58-D-21)

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 58-11-PLAN.md — vague 7 : sous-section « Poste » du manuel FR+EN, liste de clients lue par défaut dans le dossier de configuration, compte de suites, porte de phase rejouée depuis `ci.yml`, critère 6 (« en attente de la liste » si absente), ledger à la main

<!-- archive : Phase 59 (corps) (source l.640) -->

**Sources:** spec §5.2 ; SEED A-05, A-06, A-10 (vocabulaire : on garde l'existant, aucun renommage) ; `plugin/business-pilot-bundle/`, `plugin/design-orchestrator/`.
**Hors périmètre :** un fichier PRD.md séparé (A-06) ; les termes « epic » et « story » (Q-11, fermée par doctrine).
**Plans:** 8 plans

Plans:

**Wave 1**
- [x] 59-01-PLAN.md — vague 1 : gabarits produit de planning-core (PROJECT, REQUIREMENTS), minor
- [x] 59-02-PLAN.md — vague 1 : `check-prd.sh` et sa suite à mutants
- [x] 59-03-PLAN.md — vague 1 : redirection du head au poste product, minor de dev-orchestrator

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 59-04-PLAN.md — vague 2 : module, visibilité par poste, manager, workers, `prd-gate`
- [x] 59-05-PLAN.md — vague 2 : front door, skill `/vf-product`, gabarit BRIEF, README du bundle

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 59-06-PLAN.md — vague 3 : suite du bundle, baselines, compteurs des README racine
- [x] 59-07-PLAN.md — vague 3 : manuel FR et EN

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 59-08-PLAN.md — vague 4 : porte de phase rejouée depuis `ci.yml`, ledger à la main

<!-- archive : Phase 60 (corps) (source l.667) -->

**Sources:** spec §5.2 ; SEED A-07, A-08 ; `plugin/software-architecture/`, `plugin/audit-architecture/`.
**Hors périmètre :** un gate bloquant sans halt condition (Q-04 : ADR-031 penche pour l'advisory) ; `gsd-graphify` reste refusé (GSDA-08, P60-D-08).
**Plans:** 9 plans

Plans:

**Wave 1**
- [x] 60-01-PLAN.md — vague 1 : marqueur de phase `**Validation:**`, gate `check-phase-validation.sh` et sa suite à mutants
- [x] 60-02-PLAN.md — vague 1 : gabarit `ARCHITECTURE` décisionnel de planning-core, gate `check-architecture.sh` et sa suite, minor de planning-core

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 60-03-PLAN.md — vague 2 : preuve sur fixture que les lecteurs GSD rendent le même résultat avec et sans marqueur
- [x] 60-04-PLAN.md — vague 2 : verbe de pose et de validation `vf-validation.sh` (phase, architecture), poste du validateur, preuve moteur sur sa sortie

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 60-05-PLAN.md — vague 3 : worker interne `vf-product-architect`, livrable `architecture` du manager et de la front door, baseline neuve, minor du bundle
- [x] 60-06-PLAN.md — vague 3 : refus de `vf-coder` et de `vf-auto`, §5 du head (gate architecture avant découpage), champ de brief de la pose, T45, minor de dev-orchestrator

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 60-07-PLAN.md — vague 4 : minor de conductor, catalogue de ses scripts, compte de suites des README racine
- [x] 60-08-PLAN.md — vague 4 : manuel FR et EN (gate architecture, étapes proposées, comptes d'agents bornés)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 60-09-PLAN.md — vague 5 : porte de phase rejouée depuis `ci.yml`, ledger à la main (ARCG-01 partielle tant que la pose n'est pas prouvée), arrêt avant la PR

<!-- archive : Phase 61 (corps) (source l.697) -->

**Sources:** spec §5.3 ; Phase 39 (`check-divergence.sh`) ; ADR-069.
**Hors périmètre :** un workstream par rôle (deux vérités, refusé par la spec §5.3).
**Plans:** 8 plans

Plans:

**Wave 1**
- [x] 61-01-PLAN.md — vague 1 (tracer) : `vf-divergence-hook.sh` (arm, disarm, run), armement par l'engine au poste product/dev, suite à deux clones `test-divergence-deux-clones.sh` (install → hook → cri → journal)
- [x] 61-02-PLAN.md — vague 1 : champ `**Role**` des gabarits DECISIONS, LEARNINGS, BLOCKERS (source puis copies), suite `test-registres-role.sh` sur six consommateurs

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 61-03-PLAN.md — vague 2 : script du filet complet — `post-rewrite`, refus `core.hooksPath` / hook tiers / script sous l'arbre, armé à la main, `status`, journal blindé, suite `test-vf-divergence-hook.sh` à douze mutants
- [x] 61-04-PLAN.md — vague 2 : engine complet — retrait au poste solo et à `uninstall --all`, sortie `VF_DIVERGENCE_HOOK=off`, rafraîchissement à `update --all`, plan `--dry-run`, suite `test-vibeflow-update-divergence.sh` à dix mutants

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 61-05-PLAN.md — vague 3 : preuve à deux clones complète (pull en avance rapide, `pull --rebase`, worktree, branche piégée, trois témoins rouges), recette du lab réel `61-RECETTE-LAB-REEL.md` et son relevé joué
- [x] 61-06-PLAN.md — vague 3 : minors de conductor (script et engine), consolidator et reference, catalogue de conductor

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 61-07-PLAN.md — vague 4 : manuel FR et EN (filet armé, journal, limites, sortie, champ Role), compte de suites des README racine

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 61-08-PLAN.md — vague 5 : porte de phase rejouée depuis `ci.yml`, ledger à la main (COLB-08 décochée : preuve humaine), arrêt avant la PR

<!-- archive : Phase 62 (corps) (source l.726) -->

**Sources:** spec §4 C, §7 Q-05/Q-06.
**Hors périmètre :** toute implémentation de plateforme.
**Plans:** 1 plan

Plans:

- [x] 62-01-PLAN.md — dossier de décision `62-DECISION-plateforme.md` (mesures sourcées, options A/B/C) ; décision A signée par délégation le 2026-10-29 (PLTF-02), réexamen 2027-01-31 : phase close

<!-- archive : Phase 67 (corps) (source l.822) -->

> Cadrée le 2026-11-01 (`67-CONTEXT.md`, P67-D-01..18) ; planifiée le 2026-11-01.

**Success criteria** (observables, à confirmer au cadrage) :
1. Sur un lab GSD quelconque (un `.planning/` suffit), le verbe du module ouvre le cockpit et l'onglet Projet montre racine, jalon, phase et plan.
2. L'onglet Code est riche sur vibeflow-os (extracteur VibeFlow) et retombe sur le scan brut de floorplan ailleurs, sans erreur.
3. Le direct (statuts, « au travail ») arrive par le serveur floorplan unique, sans second port ni CORS.
4. L'onglet Projet se questionne : formes courantes locales et gratuites, agent actif (`claude -p`, modèle réglable) pour le raisonnement.
5. La dernière commande des sessions est masquée par défaut dans « Au travail », révélée sur demande, jamais exportée ; le chrome est en français par défaut (les textes produits par le moteur, Santé et couverture de l'onglet Code, peuvent rester en anglais, P67-D-20) sans anglais dans le reste de l'interface (test qui rougit).
6. La fenêtre est ajustable (CKPT-12, P67-D-21) : de 1 024 à 2 560 px, au chargement comme au redimensionnement à chaud, aucune superposition ni rognage de l'en-tête, des panneaux et de la barre de question ; rendu non cassé en dessous (test qui mesure les boîtes).
**Sources:** `.planning/notes/2026-11-01-cockpit-facettes.md` (arbitrages 1-4, choix de session, limites connues) ; `.planning/spikes/002-cockpit-code-projet/` (extensions, patchs P1-P8) ; `docs/research/2026-11-01-etude-floorplan-cockpit.md`.
**Hors périmètre :** enrichir l'onglet Code par stack (suite) ; retirer `vf-cockpit` (SEED-004, à la livraison).
**Plans:** 7 plans

Plans:

**Wave 1**
- [x] 67-01-PLAN.md — `dag.sh` : écriture atomique de `save()`, témoin rouge d'abord (CKPT-11)
- [x] 67-02-PLAN.md — Socle partagé : collecteur « au travail » + graphe Projet, schémas versionnés, test de forme des transcripts (CKPT-01, CKPT-06)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 67-03-PLAN.md — Vendorisation floorplan v0.6.0 @ 92d6854, retrait Cloud, marque blanche, logo (CKPT-02, CKPT-03, CKPT-04)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 67-04-PLAN.md — Mesure `claude -p`, serveur unique, direct SSE, dernière commande masquée (CKPT-05, CKPT-08, CKPT-03)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 67-05-PLAN.md — Questions : formes locales, agent confiné, sélecteur de modèle, onglet Code (CKPT-07, CKPT-06)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 67-06-PLAN.md — Module `plugin/cockpit`, skill `/vf-cockpit`, pose par l'engine (CKPT-10)

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 67-07-PLAN.md — Chrome en français, test qui rougit, recette humaine (CKPT-09)

<!-- archive : Phase 68 (corps) (source l.861) -->

> Cadrée le 2026-11-03 (`68-CONTEXT.md`, P68-D-01..21 ; P68-D-01..08 : arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-03, « Tout accepter (Recommandé) ») ; exécution après le merge de la 69 et de la PR #196 (P68-D-09, P68-D-10).

**Sources:** `.planning/notes/2026-10-29-HANDOFF-jalon-v2.md` § 3 (points à trancher : gating par module, emplacement, API des mods « early access », chemins de `driver-lock.sh`, mobile, ADR-035/031, SOBR-04) ; mémoire `vf-signal-a-embarquer-dans-vibeflow`.
**Point à cadrer (constat du 2026-11-03, accord de Samuel en session principale Claude Code, 2026-11-03) :** l'en-tête de vf-signal lit le `STATE.md` et le dossier `missions/` de l'arbre courant. Sur un arbre principal resté sur une branche ancienne, il montrait la Phase 58 et la mission 58, alors que `main` était en v2.75.0. Il ne voit pas non plus une phase menée dans un worktree (la 69 cadrée dans `.claude/worktrees/phase-69b`). Il doit signaler un arbre en retard sur `main` et voir la phase active d'un worktree. Il ne doit pas prendre une mission aux nœuds jamais refermés pour la mission en cours.
**Success criteria** (observables) :
1. Le mod vit dans le module `cockpit`, déclaré dans `plugin.json` ; `claude plugin validate plugin` est vert et l'install du module `cockpit` reste verte ; sans `cockpit=` dans le registre des modules installés, aucune surface (VFSG-01, 02).
2. La pane ne lit plus `.planning/` elle-même : ses données viennent d'un émetteur JSON versionné du socle, sans réseau (VFSG-03, 04).
3. Sur un arbre en retard de N commits sur `main` local, l'en-tête l'écrit, avec l'âge du dernier fetch ; chaque worktree apparaît avec sa branche et sa phase active (VFSG-05).
4. Une mission dont un nœud est resté `running` sans verrou ni progrès depuis plus de 1 800 s s'affiche « abandonnée », sur la pane comme sur la carte Projet (VFSG-06).
5. La pane suit Graphite, un bouton « Ouvrir le cockpit » ouvre le cockpit du lab, l'ancien mod est signalé, l'absence de `node` est dite (VFSG-07, 09, 10, 11).
6. La CI joue `validate` et `test` du mod, avec un témoin rouge sous Linux (VFSG-08) ; recette humaine sur quatre surfaces ; bump minor du module `cockpit` préparé et relecture adverse SOBR-04, le bump racine partant avec la release groupée (VFSG-12, 13 ; P68-D-31).
**Plans:** 13 plans en 9 vagues (planifiée le 2026-11-03, plan-checker interne PASSED en 2 passes ; rebasée sur `main` à 794c6dba et corrigée le 2026-11-04 après un plan-checker frais : 68-04 scindé (68-12), 68-09 scindé (68-13), P68-D-27 et P68-D-28 ; P68-D-10). **EXÉCUTÉE le 2026-11-04 : 13/13 plans, 11 passes de correction ciblée (`68-FIX-SUMMARY-INDEX.md`), recettée par juges (`68-RECETTE-HUMAINE.md`, étapes 4 et 5 reportées après la PR, P68-D-35), arbitrages P68-D-31 à P68-D-41 rendus ; PR #199 ouverte (brouillon), SANS release : module `cockpit` monté à v1.2.0, bump racine, tag et release GitHub groupés à venir (P68-D-31) ; N4, N5, N6 au BACKLOG**

Plans:

- [x] 68-01-PLAN.md — règle de mission vivante dans le socle, `avancement@2` (VFSG-06) — vague 1
- [x] 68-02-PLAN.md — retard sur `main` et worktrees sans réseau (VFSG-05) — vague 1
- [x] 68-04-PLAN.md — import du mod, déclaration plugin, forme de sortie de `claude plugin test` (VFSG-01) — vague 1
- [x] 68-03-PLAN.md — émetteur `signal@1` (VFSG-03, 11) — vague 2
- [x] 68-12-PLAN.md — gating par `cockpit=`, ancien mod (VFSG-02, 09) — vague 2
- [x] 68-05-PLAN.md — appel du socle, erreurs, en-tête (VFSG-11, 05, 06) — vague 3
- [x] 68-09-PLAN.md — CI `claude plugin validate/test` : porte de légitimité, sonde Linux, étape `ci.yml` (VFSG-08) — vague 3
- [x] 68-06-PLAN.md — retrait de `disk.ts`, vues mission/macro (VFSG-03, 06) — vague 4
- [x] 68-07-PLAN.md — équipe `who@2`, bouton « Ouvrir le cockpit » (VFSG-04, 10) — vague 5
- [x] 68-08-PLAN.md — direction Graphite (VFSG-07, 06) — vague 6
- [x] 68-13-PLAN.md — runs CI rouge puis vert sur la PR (VFSG-08) — vague 7
- [x] 68-10-PLAN.md — doc FR/EN, recette humaine, porte de phase (VFSG-12) — vague 8
- [x] 68-11-PLAN.md — bump minor du module cockpit, relecture adverse SOBR-04 ; bump racine reporté à la release groupée (VFSG-13, P68-D-31) — vague 9

<!-- archive : Phase 69 (corps) (source l.895) -->

> Cadrée le 2026-11-03 (`69-CONTEXT.md`, P69-D-01..11), cadrage mis à jour le même jour (P69-D-12..24 : équipe au travail) ; arbitrages de planification P69-D-25..27 ; planifiée le 2026-11-03 (9 plans, 5 vagues, plan-checker externe PASSED sur `b53a27f9`) ; exécutée le 2026-11-03 (9/9 plans, revue et audit sécurité passés après correction ciblée, P69-D-28 : onglets resserrés gardés en 69, arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-03) ; recette `69-RECETTE-HUMAINE.md` close le 2026-11-04 ; PR groupée avec la 68.

**Success criteria** (observables, à confirmer au cadrage) :
1. Sur le lab de la 67 (7 plans faits, 4 correctifs, STATE sur une autre phase), la carte affiche « 7/7 plans · 4 correctifs » et l'état « à recetter », jamais « 11/7 » ni « à faire ».
2. Le DAG de mission de la 67 est rattaché à la 67 (champ `phase`, puis nom `MISSION-<n>`, puis dossier de phase), plus listé dans « Missions hors phase ».
3. Un jalon `📋` dont une phase est `a-recetter` ou `en-cours` s'affiche `en-cours` ; son pied lit « 0 clos · 1 à recetter · 1 à faire · 0 % », le pourcentage restant strict (phases closes seulement).
4. Aucune lecture réseau : ni CI, ni merge, ni PR ; les étapes restantes (`reste`) viennent de traces locales seulement.
5. Chaque règle a un témoin rouge joué avant le code (quatre fixtures de lab, rouges sur le code actuel).
6. Le tiroir « Au travail » et l'onglet « Équipe » montrent l'arbre session → manager → workers, actifs et terminés depuis moins de 24 h (grisés, repliés), chaque agent avec sa dernière action lisible et relié, dans les deux sens, au nœud de mission qu'il exécute.
7. Le transcript d'un agent (mandat, messages, liste d'outils) ne se lit qu'à la demande, par requête authentifiée ; jamais de sortie d'outil ni de contenu de fichier lu ; absent du flux SSE, des fichiers générés et de l'export ; rendu en texte, CSP inchangée.
8. Le test de forme du format Claude Code rougit si un champ lu (`parentAgentId`, `spawnDepth`, `finished`, `toolUseId`, `requestShape`, `isSidechain`, `agentId`) disparaît.
**Sources:** `.planning/notes/2026-11-03-cockpit-progression-en-cours.md` (causes C1-C5, option A) ; `plugin/cockpit/scripts/vf-cockpit-project.mjs`, `vf-cockpit-planning.mjs`, `vf-cockpit-who.mjs` ; `69-CONTEXT.md` P69-D-12..24.
**Hors périmètre :** option B (pourcentage pondéré, exigence à trois états `[~]`, étapes cochées à la main) ; CI, merge, release sur la carte ; terminal intégré (Phase 71) ; lancer du travail depuis le cockpit (Phase 72).
**Plans:** 9 plans

Plans:

**Wave 1**
- [x] 69-01-PLAN.md — Avancement : témoins (a)-(d) rouges d'abord, objet `avancement@1` dans readPlanning, missions rattachées, pied du jalon, règle STATE retirée (CKPT-13..18)
- [x] 69-02-PLAN.md — Témoins rouges de la collecte de l'équipe : arbre, 24 h, rattachement, dernière action, forme Claude Code, who@2 (CKPT-19..22, 27, 28)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 69-03-PLAN.md — Socle who@2 : contrat de l'équipe, forme mesurée, arbre et historique de 24 h, direct (CKPT-19, 20, 27, 28)
- [x] 69-04-PLAN.md — Témoins rouges du transcript, de l'onglet Équipe et du rendu de l'arbre (CKPT-19..26)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 69-05-PLAN.md — Onglet Équipe servi en mémoire (patch P24), graphe equipe@1, direct (CKPT-23)
- [x] 69-06-PLAN.md — Dernière action, rattachement agent -> nœud, réducteur de transcript (CKPT-21, 22, 24, 28)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 69-07-PLAN.md — Transcript servi à la demande, garde d'émission lue du contrat (CKPT-24..26, 28)
- [x] 69-08-PLAN.md — Tiroir en arbre, liens dans les deux sens, transcript rendu en texte (CKPT-19..23, 26)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 69-09-PLAN.md — Porte de phase rejouée depuis ci.yml, suites une à une, documentation, compte de suites (CKPT-13..28)

<!-- archive : Phase 70 (corps) (source l.936) -->

> **Cadrée le 2026-11-03** (`70-CONTEXT.md`, P70-D-01..16 ; « Tout accepter (Recommandé) », arbitrage Samuel, AskUserQuestion session principale, 2026-11-03). Exécution après le merge de la Phase 69, plans revalidés d'abord (P70-D-14). Inscrite le 2026-11-03 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 : « Phase à part »).

**Sources:** `BACKLOG.md` § « Cockpit en largeur mobile et clarté de la visite guidée » (D4, I4, I5, I6, I1) et § « Cockpit : anglais résiduel et coquilles du chrome » (O5) ; § « Où en est-on ? sur un lab sans STATE » (F5, P70-D-05) ; `67-RECETTE-HUMAINE.md` ; `DESIGN.md` (direction « Graphite », PR #196, P70-D-07).
**Plans:** 12 plans

Plans:

- [x] 70-01-PLAN.md — garde du français durci, témoins rouges (UIFN-07) — vague 1
- [x] 70-02-PLAN.md — conformité DESIGN.md (garde M5) et cinq réglages visuels de l'onglet Équipe (UIFN-09, UIFN-11) — vague 1
- [x] 70-10-PLAN.md — test-cockpit-responsive.sh allégé, mêmes témoins (UIFN-01, P70-D-18) — vague 1
- [x] 70-11-PLAN.md — focus clavier du tiroir et témoins des mineurs de la 69 (UIFN-12, UIFN-13) — vague 1
- [x] 70-03-PLAN.md — anglais résiduel et coquilles du chrome, texte de la visite (UIFN-06, UIFN-04) — vague 2
- [x] 70-04-PLAN.md — en-tête mobile sur une rangée, menu « ⋯ », onglets à 13 px (UIFN-01, P70-D-16) — vague 2
- [x] 70-05-PLAN.md — zoom en pile, tiroir téléphone, titre coupé (UIFN-02, UIFN-03, UIFN-06) — vague 3
- [x] 70-06-PLAN.md — « Où en est-on ? » sans STATE, statuts en français (UIFN-08, UIFN-06) — vague 3
- [x] 70-07-PLAN.md — visite « Par où commencer » corrigée (UIFN-04) — vague 4
- [x] 70-12-PLAN.md — zoom, titre et fil d'Ariane de l'onglet Équipe, matrice responsive (UIFN-14) — vague 4
- [x] 70-08-PLAN.md — visite propre à l'onglet Projet (UIFN-05) — vague 5
- [x] 70-09-PLAN.md — captures avant/après, recette par juges frais, bump patch v1.1.2 (UIFN-10) — vague 6

<!-- archive : Phase 71 (corps) (source l.961) -->


**Sources:** `69-CONTEXT.md` P69-D-19 et P69-D-20.
**Plans:** 11 plans (6 vagues)

Plans:

- [x] 71-01-PLAN.md — vague 1 : tranche traçante `--terminal` de bout en bout (patch P25 de `serve.mjs`, serveur Q, amorçage, session, assistant PTY dans l'arbre du moteur) — TERM-01, 05, 07
- [x] 71-02-PLAN.md — vague 2 : contrôles Host/Origin/jeton de Q, tenue des secrets — TERM-02, 03
- [x] 71-03-PLAN.md — vague 2 : assistant PTY complet, environnement filtré, plein écran par le flux, orphelins — TERM-06, 07, 08, 09
- [x] 71-04-PLAN.md — vague 2 : session unique, grâce de 30 s, tampon de 256 Kio, rien sur disque — TERM-08, 11
- [x] 71-10-PLAN.md — vague 2 : lanceur `--terminal` et amorçage — TERM-01, 03, 04, 07
- [x] 71-11-PLAN.md — vague 2 : xterm.js vendorisé (sha256, licences, `VENDORED.txt`) — TERM-10
- [x] 71-05-PLAN.md — vague 3 : page Q et sa CSP, thème, parité des variables — TERM-05, 10, 12
- [x] 71-06-PLAN.md — vague 4 : client Q, cadre sous `sandbox`, canal Q vers P, 0 violation CSP — TERM-04, 05, 10, 12
- [x] 71-07-PLAN.md — vague 5 : tiroir dans Projet et Code (O1 décidé : P71-D-20) — TERM-01, 05, 07, 12
- [x] 71-08-PLAN.md — vague 5 : bout en bout dans Chrome, séquences hostiles, chaîne XSS — TERM-09, 10, 12
- [x] 71-09-PLAN.md — vague 6 : recette humaine, docs, version, gates, `71-SECURITY.md` — TERM-05, 08, 09, 12

