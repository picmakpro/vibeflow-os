---
gsd_state_version: 1.0
milestone: fiabilite-v1.0
milestone_name: « ce qui survit »
current_phase: 33
current_phase_name: Watchdog & notifications des missions
status: gaps_found
stopped_at: Phase 33 — 5 plans exécutés sur 3 vagues (branche feat/phase-33-watchdog-notifications, depuis mergée dans main — vérifié machine le 2026-08-17), vérifiée goal-backward le 2026-08-17 (`33-VERIFICATION.md`) — 4/4 critères ATTEINTS (WTCH-03 en limite assumée : preuve Windows réelle non exécutée). Le gap WTCH-02 relevé par la vérification (relais stall inatteignable au geste `dag.sh mark`) est fermé par D-33-G (`88975dc`), cas de discriminance T49, mesure A/B re-jouée par le manager ; hygiène documentaire + bump module `conductor` v1.27.0 faits. **ROUVERTE le 2026-08-17 par son annexe D-33-H** (notifications OS en opt-in, défaut OFF) puis **re-livrée** — plans 33-06 (gate d'opt-in + toggle `/vf-notify`) et 33-07 (Pattern H, relais des jalons GSD) exécutés sur la branche `feat/phase-33-annexe-notifications-opt-in`, modules `conductor` v1.28.0 et `dev-orchestrator` v2.18.0 ; vérification goal-backward de l'annexe (`33-VERIFICATION-ANNEXE.md`) 5/6 critères, critère 1 PARTIEL fermé par `401c903` (garde `${HOME:-}` + cas N19). 66 suites / 0 KO, `check-version-sync.sh` exit 0. **Branche non mergée, non poussée — aucune PR, aucun tag, aucune release**, en attente d'un geste humain
last_updated: "2026-08-17T00:00:00.000Z"
last_activity: 2026-08-17
last_activity_desc: Phase 33 (Watchdog & notifications des missions) — 5 plans livrés (progress_epoch/mark-progress WTCH-01, sous-contrôle stall/abandon check-guard-health.sh WTCH-02, notify.sh portable WTCH-03, armement par gate PORT-05 WTCH-04) ; vérification goal-backward `gaps_found` (1 gap sur le relais D-33-F au geste `mark`) puis gap FERMÉ par D-33-G (`88975dc`, cas T49) ; hygiène documentaire de clôture (STATE/ROADMAP/REQUIREMENTS) + bump module `conductor` v1.27.0. Puis ANNEXE D-33-H (2026-08-17) — notifications OS passées en opt-in défaut OFF (33-06) + jalons GSD relayés vers l'app Claude par Pattern H (33-07), `conductor` v1.28.0 + `dev-orchestrator` v2.18.0, branche d'annexe non mergée
progress:
  total_phases: 8
  completed_phases: 2
  total_plans: 17
  completed_plans: 16
  percent: 25
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-26 — charte rouverte : 17 modules, D2/D6 renversées)

**Core value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.
**Current focus:** Milestone fiabilite-v1.0 — Phase 30 (Portabilité Windows II), Phase 31 (Manifeste d'install + dry-run, issue #20) et Phase 32 (Durcissement du driver-lock) livrées ; Phase 33 (Watchdog & notifications des missions) exécutée, vérifiée le 2026-08-17 — `gaps_found` puis gap fermé (D-33-G) : 4/4 critères atteints, WTCH-03 en limite assumée (preuve Windows réelle non exécutée) ; **rouverte le même jour par son annexe D-33-H** (opt-in défaut OFF + jalons vers l'app Claude) et re-livrée sur `feat/phase-33-annexe-notifications-opt-in`, non mergée
`get-shit-done-cc` → `@opengsd/gsd-core` livrée en v2.39.0 atteint enfin les **postes déjà équipés** :
`/vf-update` dit l'état du moteur avant tout stop et propose la bascule sous confirmation ADR-031.
Modules `dev-orchestrator` v2.7.0 + `conductor` v1.16.0. Verdict `19-VERIFICATION.md` : **PASS 6/7**.
Phase 17 **terminée, vérifiée et SHIPPÉE `v2.42.0`** (2026-07-28) — signaux de démarrage
du moteur de dev (`check-dev-bootstrap.sh`, `check-doc-drift.sh`, `discover-unintegrated-docs.sh --hook`,
hooks `SessionStart`), module `dev-orchestrator` v2.6.0. SC5 (advisory/lecture seule) et SC6
(portabilité macOS+Linux) prouvés par exécution, pas par lecture. Plus aucun milestone ouvert.
**Release `v2.42.0` publiée** le 2026-07-28 (tag annoté + release GitHub, `check-release-tag --remote`
✓, `check-version-sync` ✓ après synchro 39 → 41 suites dans les deux README).
Phase 18 **requalifiée en variante réduite** le 2026-07-28 (étude `STUDY.md`, verdict GO-RÉDUIT) —
non démarrée. Pré-requis bloquant : la RFC upstream `open-gsd/gsd-core` part **avant** toute
implémentation du gate.

**Dette backlog héritée — CLOSE le 2026-07-28** (commits `607844c`, `213ea1a`, hors release) :

- `known-versions.txt` jamais posé → cause racine corrigée côté engine. `copy_module_scripts()`
  pose désormais les fichiers de données `*.txt` (sans `chmod +x`) ; T9 borne le glob par le bas
  et par le haut, discriminance prouvée par mutation.

- `brick_routed()` grep naïf → fonction rendue **stricte** (la carte est la seule source, comme la
  spec du 2026-07-25 l'affirmait déjà). Mesure : sur 71 briques, **0** n'était couverte par un
  repli seul — les deux gardes étaient mortes ET rendaient T14 insensible. T14c les remplace par
  un filet qui échoue si une brique est citée par un SKILL.md sans l'être par la carte.
  Discriminance prouvée par mutation sur `gsd-quick`, le cas partagé qui produisait le faux vert.

Autre candidat restant : sortie d'expérimental de `mobile-test`(-team). Reliquat non traité :
templates-mémoire jamais posés à l'install (arbitrage engine, cf. §Decisions) — la correction
`*.txt` ci-dessus ne les couvre pas (ce sont des `.md` dans un sous-dossier).

## Current Position

Phase: 33 (Watchdog & notifications des missions) — **rouverte puis re-livrée par son annexe
D-33-H**, branche `feat/phase-33-annexe-notifications-opt-in`, non mergée et **non poussée**
Plan: 33-07 (dernier plan exécuté de l'annexe) ; hygiène documentaire de clôture faite (2026-08-17)
Status: Phase 33 annexe D-33-H livree - branch feat/phase-33-annexe-notifications-opt-in - not
merged, not pushed (2026-08-17)
Last activity: 2026-08-17 — annexe D-33-H : notifications OS en **opt-in (défaut OFF)** derrière un
fichier-sentinelle scope machine + toggle `/vf-notify` (33-06, `conductor` v1.28.0), et jalons GSD
(fin de phase, fin de milestone) relayés vers l'app Claude par **Pattern H** / `SendMessage(main)`
(33-07, `dev-orchestrator` v2.18.0). Vérification goal-backward de l'annexe : 5/6 critères, le
critère 1 (fail-open inconditionnel) fermé après coup par `401c903`. Mesures : 66 suites / 0 KO,
`check-version-sync.sh` exit 0, `check-agents.sh --agents-dir=plugin/dev-orchestrator/agents`
exit 0.

**En attente d'un geste humain** (ADR-031) : push de la branche, PR, merge, puis release racine —
`VERSION` / `plugin.json` / `marketplace.json` sont sciemment intacts, et `plugin/commands/vf-notify.md`
vit au niveau plugin : il n'atteindra un lab qu'au bump du triplet racine, pas au seul bump de
`conductor`.

Précédent (vérifié machine le 2026-08-17, `git merge-base --is-ancestor <branche> main`) : les
branches des Phases 30, 31, 32 **et** du tronc de la Phase 33 sont toutes **mergées dans `main`**.
Releases correspondantes : `v2.53.0` + hotfix `v2.53.1` (Phase 30, PR #43), `v2.54.0`, `v2.55.0`,
`v2.55.1` — dernier tag posé, `VERSION` courante. La `v2.56.0` a été **retirée** avant toute
distribution (revert `07ff554`), ce qui est précisément la fenêtre qui a rendu l'annexe D-33-H
gratuite : aucun lab n'a jamais reçu le défaut d'émission.

## Performance Metrics

**Velocity:**

- Total plans completed: 18+ (13 mesurés phases 1-6 ci-dessous + 6 en Phase 12 + 7 en Phase 14 ;
  le compteur automatique n'a jamais été alimenté — reconstruit le 2026-07-26)

- Average duration: ~6 min/plan (sur les 13 plans mesurés)
- Total execution time: non mesuré au-delà de la Phase 6

**By Phase:** *(mesures disponibles uniquement — phases 7, 8, 9, 12 et 14 non instrumentées)*

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 01-dev-orchestrator P01 | 10min | 2 tasks | 6 files |
| Phase 01 P02 | 10 | 2 tasks | 1 files |
| Phase 01-dev-orchestrator P03 | 12 min | 2 tasks | 2 files |
| Phase 01 P04 | ~6 min | 2 tasks | 13 files |
| Phase 01-dev-orchestrator P05 | ~10min | 2 tasks | 4 files |
| Phase 02-manifeste-resolveur P01 | 5min | 2 tasks | 8 files |
| Phase 02-manifeste-resolveur P02 | ~5min | 2 tasks | 2 files |
| Phase 03-engine-scope-aware P01 | 3min | 3 tasks | 2 files |
| Phase 03 P02 | 6min | 2 tasks | 2 files |
| Phase 04 P01 | ~1 min | 2 tasks | 3 files |
| Phase 04 P02 | 5min | 2 tasks | 3 files |
| Phase 05 P01 | 2 | 3 tasks | 5 files |
| Phase 06 P01 | 1min | 2 tasks | 2 files |
| Phase VFDO-19 P01 | 15min | 3 tasks | 2 files |
| 27 | 6 | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase VFDO-19 P02 | 90min | 3 tasks | 4 files |
| Phase 20 P07 | ~1h10 | 3 tasks | 26 files |

## Accumulated Context

### Roadmap Evolution

- 2026-08-15 (roadmap fiabilite-v1.0) : **feuille de route du milestone posée — 8 phases**.
  Numérotation arbitrée par l'humain : les héritées gardent 18 et 25, les nouvelles continuent à
  30 (le milestone précédent s'est arrêté à 29). Ordre dicté par les fichiers (ARCHITECTURE.md
  §4) : **30** Windows II (première — demande client ; porte les gestes jour 1 : LEDG-03/RFC
  upstream + WKTR-03/veille gsd-core) → **31** Manifeste + dry-run (#20 ; strictement après 30,
  mêmes fichiers `_internal/`) → **32** Driver-lock → **33** Watchdog (adjacentes — heartbeat
  partagé, WTCH après LOCK) → **18** héritée (survie du ledger — livrée avant clôture, sinon 3ᵉ
  dérive) → **34** Gaps agency-agents + cadrage SKIL-01 rattaché → **25** héritée (budget
  d'instructions, avant-dernière, périmètre réduit BUDG-01/02) ; **35** Ré-armement worktree
  flottante conditionnelle (gsd-core > 1.10.0 releasé ET installé — NON satisfaite au 2026-08-15,
  npm latest = 1.10.0). Couverture : 30/30 IDs du ledger mappés (0 orphelin, 0 doublon) ; QUAL-01
  transverse, reporté en critère sur chaque phase livrant un gate. Pré-requis de cadrage bloquant
  de la Phase 30 : PORT-04 (affectation §3.2 tranchée avec Willy avant le plan).

- 2026-08-15 (suite) : **Phase 29 cadrée** — CONTEXT.md posé (cadrage court choisi : périmètre
  verrouillé D-01/D-02/D-03, zones grises en Claude's Discretion), DISCUSSION-LOG.md en trace.
  Prochain geste : plan (researcher → planner → checker) puis **exécution complète via
  `vf-dev-manager`** (demande explicite de Samuel, session du 2026-08-15).

- 2026-08-15 : **Phase 29 ajoutée — « Distiller les gains ICM (G1-G5) — investigation dag.sh
  --scope d'abord »**, issue de la deep-search ICM du même jour
  (`reports/research/2026-08-15-icm-deep-search.md`, session en direct hors Phase 28). Périmètre :
  les 5 gains distillables du rapport (anti-drift carte↔disque, Load/DO NOT Load, Edit-Source,
  CONTEXT par compartiment, lab-starters clonables — ce dernier candidat au découpage), avec une
  précondition transverse posée par Samuel : investiguer l'historique et les consommateurs de
  `dag.sh --scope` avant tout geste G1, **zéro régression autorisée** sur le mécanisme de scope.
  Branche dédiée `docs/phase-29-icm-gains` (la branche 28 reste vierge de tout contenu ICM).

- 2026-08-10 : **Phase 28 ajoutée — « Preuve que ce qui est armé dans le plugin est armé chez
  l'utilisateur »**, ouverte par la régression #38 (13 agents distribués avec `isolation: worktree`
  alors que leur précondition `worktree.baseRef: "head"` n'était posée que dans le settings local de
  ce repo). **Créée avec le diagnostic, délibérément NON cadrée** : Samuel met VibeFlow à jour
  avant de la travailler, et ce que la mise à jour change doit être re-mesuré au cadrage plutôt que
  présumé dans l'entrée de roadmap. Deux corrections d'hygiène au passage : le CLI amont
  (`phase.add`) a inséré la phase **au milieu de la Phase 24** — bloc déplacé à la main en fin de
  roadmap ; et la table de suivi, arrêtée à la Phase 25, a reçu les lignes 26, 27 et 28.

- 2026-08-01 : **Phase 23 plan 01 exécuté hors-bande** — mandat étroit (un seul plan sur 8) confié
  dans le worktree `vibeflow-os-p23` (branche `feat/phase-23-couplage-gsd`), sans passer par
  `gsd-execute-phase` pour la phase entière. Livré : le contrat de checkpoint amont (`gate`,
  `reprise`) et le désarmement du flag `workflow._auto_chain_active` — détail complet :
  `.planning/phases/VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-/23-01-SUMMARY.md`.
  Compteurs `total_plans`/`completed_plans` incrémentés en conséquence (+1 chacun) ;
  `current_phase`/narratif Phase 21 volontairement laissés intacts (ADR-063 : ne jamais
  réparer ce fichier par `gsd-tools state`, et la Phase 23 n'est pas encore la phase courante
  suivie ici). Les 7 autres plans de la Phase 23 restent à exécuter.

- 2026-08-01 : **Phase 26 ajoutée** — « Manuel utilisateur VibeFlow (manual/) ». Origine : demande
  de Samuel (réorganiser les specs et offrir une doc lisible aux arrivants sans les plonger dans
  les docs de gestion de projet). Un manuel « vitrine » sous `manual/` à la racine : arborescence
  thématique numérotée qui descend progressivement sous le capot, pages courtes chaînées
  prev/sommaire/next, index avec graphiques mermaid, bilingue FR + EN. `README`/`INSTALL`
  maigrissent et pointent dessus au lieu de dupliquer. Cible : lecteurs humains — ce dossier sera
  généralement ignoré par les agents de maintenance du repo.

- 2026-07-31 : **Phase 22 ajoutée** — « Hygiène documentaire — doctrine de sortie et captation
  d'intention ». Origine : demande de Samuel (« le dev-orchestrator n'a pas de workflow de mise à
  jour de doc avec les commandes GSD qui maintiennent la doc et les specs »). Gap établi **sur
  pièce** par lecture des workflows amont (`gsd-core/workflows/docs-update.md`, 1177 lignes, 17
  steps ; `ingest-docs.md` ; `map-codebase.md` ; `extract-learnings.md`) confrontés à l'état du
  module. **Le manque n'est pas d'outils mais de discernement** : les quatre familles
  documentaires que GSD outille séparément (doc **produit** → `gsd-docs-update` ; doc **d'entrée**
  → `gsd-ingest-docs`/`gsd-import` ; doc **du code** → `gsd-map-codebase` ; doc **de savoir** →
  `gsd-extract-learnings`/`gsd-graphify`) sont fondues en une ligne unique d'`intent-routing.md`.
  Quatre lacunes nommées : (1) aucune doctrine de sortie symétrique d'`ingestion-flow.md`, et les
  flags porteurs de sens de `gsd-docs-update` (`--verify-only` = auditer sans écrire, `--force` =
  régénérer) exposés nulle part ; (2) captation d'intention famélique — une seule ligne de
  formulations ; (3) `vf-dev-manager` sans table de moments déclencheurs et `vf-design-manager`
  sans aucun geste documentaire ; (4) le signal `[doc-drift]` (Phase 17) constate le fait mais
  personne n'est outillé pour le graduer. **Dépend du merge de la Phase 20** (fichiers partagés :
  `intent-routing.md`, `mission-contracts.md`, `vf-dev-manager.md`) ; **indépendante de la Phase
  21**, ordre libre.

- 2026-07-31 : **Phase 21 ajoutée** — « Alignement du moteur GSD sur gsd-core 1.9.0 ». Origine : la
  mise à jour du moteur de 1.8.0 vers 1.9.0 sur le poste de Samuel le 2026-07-31 (11:35). Delta
  établi **sur pièce** (`npm pack` des deux versions + diff intégral des tarballs + vérification de
  l'installation vivante), archivé en `.planning/missions/2026-07-31-delta-gsd-core-1.9.0.md`.
  **Vérifié avant ouverture : le dispatch tient** — aucun frontmatter d'agent modifié, 71 skills des
  deux côtés sans ajout ni suppression, `_runtime-launcher.snippet.sh` identique, 43 suites vertes,
  gates `check-gsd-engine.sh` / `detect-gsd-engine.sh` au vert. La phase est de l'**alignement**, pas
  du sauvetage, sauf sur un point : l'injection MCP ADR-051 est **structurellement inopérante** sur
  ce poste (`inject-mcp-tools.sh` dérive ses serveurs de `./.mcp.json`, or les serveurs sont en
  **scope global** dans `~/.claude.json` — `--verify` sort en `3 / INDÉTERMINÉ` au lieu de signaler
  le manque, et `gsd-executor` est aveugle à XcodeBuildMCP sur les labs iOS). Périmètre arbitré par
  Samuel : **une phase unique, exhaustive, rituel allégé** — injection MCP, contrat
  `estimate:`/`actuals:` (ADR-2629 amont), recouvrement avec les lanes de revue amont (ADR-2782) vs
  l'étage de revue livré en 20-06, `runtime-aware-dispatch` (#2508) et `executor-isolation-dispatch`,
  purge de la dette de version 1.8.0 (dont le **cas 8 de `test-check-gsd-engine.sh` qui asserte la
  chaîne littérale `1.8.0`**), et statut des hooks 1.9.0 non câblés. **Dépend du merge de la Phase
  20** — même règle que le diagnostic du 2026-07-29.

- 2026-07-28 : **Phase 20 ajoutée** — « Fluidité du flux de dev sans perte de qualité ». Origine :
  **second rapport de l'audit externe du 2026-07-28** (même lab `ExploreSomfy`, tranche iOS en 5
  lots dont 2 parallélisés par worktrees, ~90 commits, suite 177 → 331 tests), archivé en
  `.planning/missions/2026-07-28-audit-externe-fluidite.md`. **Les 4 constats ont été vérifiés sur
  pièce avant ouverture** — verdict : 3 confirmés dont 2 **plus solidement que le rapport ne
  l'affirme**, 1 **partiellement daté**.

  - **Changement 1 (ADR-051)** confirmé et aggravé : les `tools:` déclarés de `vf-reviewer`,
    `vf-auditer` et `vf-design-judge` gagnent tous **`Write, Edit` au runtime** (`memory: project`),
    et la description de `vf-design-judge` affirme une barrière « sans Write ni Edit » que le
    runtime ne pose pas. Le moindre privilège invoqué par ADR-051 n'existait déjà plus.

  - **Changement 2 (revue graduée par risque)** confirmé et verrouillé par un fait que le rapport ne
    citait pas : `vf-dev-manager.md:108` **interdit explicitement** au manager d'ajouter une revue
    (« Pas de double revue »). La revue est donc le seul étage à la fois obligatoire
    (`vf-coder.md:34`, en dur) **et hors de portée du manager**. Gradation existante indexée sur le
    volume (`SEUIL_EQUIPE = 3`), jamais sur le risque.

  - **Changement 3 (`MISSION-INVARIANTS.md`)** confirmé sur sa partie vérifiable (le gabarit
    `mission-contracts.md` existe et a été court-circuité ; `vf-dev-manager.md:29` lit déjà le
    `CLAUDE.md` du projet). L'absence des 3 invariants sur disque porte sur `ExploreSomfy` et n'est
    **pas vérifiable depuis ce repo** — statut plus faible que les autres constats.

  - **Changement 4 (`check-agents.sh`) — DATÉ à moitié** : l'option d'exclusion demandée **existe
    déjà** (`--third-party-prefix`, défaut `gsd-`, `check-agents.sh:84`), livrée en Phase 16 /
    v2.41.0 le 2026-07-27, **la veille du rapport**. Mesure du jour : **23 lignes, pas 68** — 21
    warnings tous sur des agents `vf-*`, 34 tiers `gsd-*` écartés, zéro finding `gsd-`. Reste vrai
    et non corrigé : `AGENTS_DIR=".claude/agents"` relatif au cwd (`:78`) + hook appelé sans
    `--agents-dir` ⇒ **le hook sort 0 ligne, le garde-fou ne regarde rien**. La correction, jugée
    impraticable le 28/07, est devenue praticable — et ferait remonter l'écart du changement 1.
  Découpage **arbitré par Samuel : une phase unique pour les 4 changements**, contre la
  recommandation de scinder en {1,4} conformité observable et {2,3} pilotage de mission. Réserve
  inscrite au ROADMAP : si l'exécution déborde, c'est par le changement 2 qu'il faudra scinder.

- 2026-07-28 : **Phase 19 ajoutée** — « Migration du moteur GSD pilotée par `/vf-update` ». Origine :
  **audit externe sur un second poste** (lab `ExploreSomfy`, scope user, rapport archivé en
  `.planning/missions/2026-07-28-audit-externe-migration-opengsd.md`), dont les 5 constats ont été
  **recoupés ligne à ligne dans ce repo** avant ouverture. Fait porteur : la migration
  `get-shit-done-cc` → `@opengsd/gsd-core` livrée en **v2.39.0** n'atteint **aucun poste déjà
  équipé** — plugin à 2.42.0, moteur toujours à 1.42.3 posé le 16/07, 12 jours après l'install et 2
  jours après la livraison de la migration. Trois causes vérifiées : `detect_gsd()` fait un `skip`
  sur le layout legacy (`ensure-deps.sh:119-120` + `:133`) ; aucun chemin d'update n'appelle
  `ensure_gsd()` (`vf-update/SKILL.md` §Garde-fous place le moteur hors périmètre) ;
  `log_legacy_cleanup_if_needed()` (`:184`) n'est joignable que par `/vf-init` et `/vf-calibrate`.
  Périmètre arbitré avec le mainteneur : **détecter + proposer sous confirmation ADR-031** (pas
  seulement dire), les 5 trous dans la même phase, **sans** hook `SessionStart` supplémentaire.
  Piège acté : **1.8.0 < 1.42.3 en semver** — le classement se fait sur le nom du paquet et le
  layout, jamais sur les numéros. Nuance portée au rapport : `check-plugin-update.sh` ne compare que
  les tags du plugin, aucun comparateur n'est en défaut aujourd'hui. **Indépendante de la Phase 18**
  (elle, bloquée par la RFC upstream) — donc exécutable immédiatement.
  Second rapport du même audit (fluidité du framework, 4 changements dont la révision d'ADR-051 et
  la gradation de la revue par risque) archivé en
  `.planning/missions/2026-07-28-audit-externe-fluidite.md` — **non instruit**, à arbitrer après.

- 2026-07-28 : **Phase 18 requalifiée en variante réduite** — « Survie du ledger d'exigences à la
  clôture de jalon ». Étude d'implémentation
  `.planning/phases/VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon/STUDY.md` (branche
  `phase-18-living-specs-study`, commit `0c2ecf7`) : verdict **GO-RÉDUIT**. Les 4 briques de
  l'inscription du 2026-07-27 (grammaire delta, ledger par capability, overlay `ship:post`, skill de
  spec-sync agent-driven) sont **écartées** — quatrième registre sans en retirer aucun (`ROUT-01` en
  3 copies) ; chemin agent-driven d'OpenSpec volé sans les 16 garde-fous du chemin `archive` ;
  ancrage `ship:post` réel en gsd-core 1.8.0 mais inopérant ici (`/gsd-ship` jamais emprunté,
  `onError: skip`, gate `bundleContentHash`). Le trou prouvé restant : `complete-milestone.md`
  supprime `.planning/REQUIREMENTS.md` **inconditionnellement** à chaque clôture. La RFC upstream
  `open-gsd/gsd-core` passe de bonus à **dépendance bloquante** (condition D3, échéance
  **2026-10-26**). Dossier de phase renommé en conséquence
  (`VFDO-18-capability-living-specs-conventions-openspec` →
  `VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon`, slug régénéré par
  `gsd-tools query generate-slug`). Les `*-SUMMARY.md` de la Phase 17 citent l'ancien chemin :
  laissés intacts, ce sont des constats datés.

- 2026-07-27 : **Phase 18** (Capability living-specs, conventions OpenSpec) ajoutée. Issue de
  l'étude « successeurs de GSD » du jour (mémoire `gsd-succession-landscape-2026-07`) : gap réel
  confirmé — GSD n'a aucun ledger de specs accumulées « ce que le système EST » ; verdict des audits
  code : ne PAS co-installer OpenSpec (collision de routage des skills, double état), voler la
  convention (grammaire delta + merge par bloc Requirement/Scenario) via une capability overlay
  `.gsd/capabilities/` sur `ship:post`, specs sous `.planning/specs/`. Piste amont : RFC/PR vers
  open-gsd/gsd-core une fois la capability éprouvée dans VibeFlow.

- 2026-07-27 : **Phase 17** (Signaux de démarrage du moteur de dev) ajoutée. Spec :
  `docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md`. Constat déclencheur :
  `dev-orchestrator` est le seul module structurant **sans hooks**, donc `discover-unintegrated-docs.sh`
  (livré Phase 13) n'est jamais appelé automatiquement et rien ne guide l'utilisateur après l'init.
  Incident du jour qui a élargi le périmètre : une demande de conception adressée au Claude principal
  est partie sur `superpowers:brainstorming` alors que ce repo tourne sous GSD avec une Phase 16
  inscrite — `planning-core` se retire quand GSD tient le projet (`--defer-to-gsd`), aucun module ne
  prend le relais, et le routage de `vibeflow-dev` n'existe que si son `AGENT.md` est lu (donc jamais
  avant invocation). D'où un 5e signal `[gsd-engine]` d'orientation. Indépendante de la Phase 16.

- 2026-07-27 : **Phase 15** (Collaboration inter-équipes dev ↔ design) ajoutée. Constat déclencheur :
  les deux équipes de mission s'ignorent totalement (seul pont = routage conversationnel
  `vibeflow-dev` → skill `vf-design`) ; les specs de `vf-crafter` ne sont jamais implémentées ; la
  description de `vf-design-manager` revendique un dispatch par `vf-auto` qui n'existe pas. Étude +
  7 tests empiriques (2026-07-27) : option A retenue — étages croisés sous UN manager, imbrication
  manager→manager interdite (Pattern A prouvé bloquant), DAG hétérogène déjà supporté par le kernel.

- 2026-07-26 : **Phase 13 redéfinie sans verbe-façade** — la phase était écrite autour de `/vf-ingest`
  et du cycle `vf-brainstorm → vf-ingest → vf-plan → vf-execute`, supprimés en v2.33.0. BRDG-01..03 et
  les critères de succès réécrits : ingestion portée par l'agent `vibeflow-dev`, découverte outillée
  (13-01). Plan 13-01 committé et réparé (corpus 8 → 9 documents, markup parasite purgé).

- 2026-07-25 : Milestone **gsd-migration** créé (VOC-02 promu). Phase 10 (Étude & faisabilité migration GSD)
  + Phase 11 (Intégration, GATE Phase 10) ajoutées à la feuille de route. Requirements GSDM-01..06.
- 2026-07-25 : Milestone **vf-routing** créé. Phase 12 (Routage fin & couverture complète des verbes `/vf-*`)
  + Phase 13 (Pont spec → feuille de route) ajoutées. Requirements VERB-01..05, BRDG-01..03.
  Devient le milestone actif ; `gsd-migration` reste ouvert en attente (chantiers indépendants).

- 2026-07-25 : **Phase 14** (Frontière d'altitude planning-core / moteur GSD) ajoutée au milestone vf-routing.
  Constat déclencheur : `vf-planning` et la chaîne GSD produisaient les mêmes fichiers dans le même dossier
  avec des frontmatters **incompatibles** (`planning_version` vs `gsd_state_version`) — deux moteurs de
  planning concurrents. Décision : ADR-055, frontière d'altitude (un projet = un seul moteur ; VibeFlow tient
  le lab et l'enforcement). Requirements ALTI-01..05, 6 plans sur 4 vagues, indépendante des Phases 12 et 13.

- 2026-07-25 : compteurs de `progress` corrigés — ils affichaient `total_plans: 0` alors que la Phase 12
  comptait déjà 6 plans dont 1 livré (12-01). Réel : 12 plans posés (6 en Phase 12, 6 en Phase 14), 1 livré.

- 2026-08-04 : **Phase 23 — 6 plans sur 8 exécutés et revus** (mission d'équipe `vf-dev-manager`,
  worktree `vibeflow-os-p23`, branche `feat/phase-23-couplage-gsd`). 23-01 à 23-05 sont clos
  (exécution + revue en régime plein) ; 23-06 est exécuté, sa revue tourne. Restent 23-07 et 23-08.
  Le suivi détaillé, les arbitrages et les dettes vivent dans `.planning/HANDOFF.json` et
  `.planning/MISSION-23.dag.json` du worktree — **c'est là qu'il faut regarder pour reprendre**,
  pas ici.
  **Deux faits structurants pour la suite** : (a) `vf-dev-manager.md` est à **241/250** (ADR-029),
  soit **9 lignes de marge** alors que 23-07 ET 23-08 le touchent tous les deux — la soupape est
  le déport vers `plugin/dev-orchestrator/references/`, qui n'est pas plafonné ; (b) **aucune
  exécution GitHub Actions n'a eu lieu sur cette branche** (`gh run list` vide), donc la CI de la
  phase — y compris le canari de forme du moteur ajouté par 23-02 — n'a jamais tourné pour de vrai.
  **Arbitrages rendus en mission** : A-15 (A-10 périmée sur `mission-flow.md`, appliquée sur
  `check-gsd-config.sh`). **En attente de Samuel** : fuite d'info par symlink dans `slurp()` des
  deux scripts, promotion d'A-15 en ADR, push de la branche pour exercer la CI, ratification O-16.

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (D1–D6).
Recent decisions affecting current work:

- **2026-08-16/17 — Phase 32 (Durcissement du driver-lock) : cadrage et plans arrêtés, quatre
  arbitrages humains, tous nés d'une mesure qui contredisait une prémisse écrite.** Détail :
  `32-CONTEXT.md`, preuves dans `32-SPIKE-reference-transaction.md`, `32-REJEU-contournements.md`,
  `32-TERRAIN.md`.

  1. **D-32-A (1B) — le blocage du checkout ne passe PAS par `reference-transaction`.** Le spike a
     rendu *PAS SÛR* : le hook wedge `rebase` en refusant son propre `--abort`, casse `worktree add`
     en fuitant la branche, se contourne par `-c core.hooksPath=/dev/null` — que quatre de nos
     `check-*.sh` utilisent déjà — et est aveugle sur git < 2.46. Le blocage est porté par le guard
     `PreToolUse(Bash)`, qui refuse avant que git ne tourne. Critère 3 du ROADMAP amendé.

  2. **D-32-B (2B) — le guard couvre `Bash` PLUS `Write|Edit` restreint à `.planning/`.** Le rejeu
     a montré **4 incidents / 3 gestes**, pas 2 : l'incident du 2026-07-31 est passé par les outils
     d'écriture natifs, hors de portée d'un guard Bash seul. Critère 2 amendé.

  3. **D-32-QUAL (QUAL B) — « BRUYANT » n'existait pas.** Mesuré : `exit 17` + stderr n'atteint ni
     le modèle ni l'humain, `systemMessage` sur `allow` n'atteint pas le modèle, et les marqueurs
     `VF_GUARD_HEALTH_DIR` n'ont **aucun consommateur** — le « hook doctor » spécifié le 2026-08-02
     n'a jamais été écrit. Extension de périmètre assumée : la phase livre ce hook doctor
     `SessionStart`, **générique** (lecteur des marqueurs de tout le parc), avec sa suite et sa
     mutation. QUAL-01 passe à **quatre** issues, pas trois.

  4. **3B et 4A (2026-08-17) — le périmètre « ne touche que `conductor` » est tombé, et un trou
     préexistant du lock est corrigé.** `acquire` cessant de récupérer un lock périmé, 5 agents
     managers de 4 modules tiers + `mission-flow.md` + un README prescrivaient un contrat mort :
     synchronisation doctrinale complète retenue (option 3B), plus un champ `hint` in-band sur le
     refus. Et (4A) un lock **legacy** frais tenu par autrui laissait un second `acquire` rendre
     `acquired:true` — deux détenteurs, mesuré, avec le cas T12 qui passait *par* ce bug : corrigé
     dans la phase, ce qui ne rouvre pas le protocole symlink-génération mais ferme sa voie legacy.

  **Leçon de méthode, la même qu'en Phase 31** : le plan-checker interne a rendu « PASSED,
  0 blocker » ; deux vérificateurs frais dispatchés en direct ont trouvé **9 bloquants et
  15 findings**, la plupart vérifiés par exécution — dont un guard aveugle au chaînage par saut de
  ligne, qui aurait laissé passer l'incident I4 avec tous les cas de test verts.

  **Complément de livraison (2026-08-17) — Phase 32 exécutée, 64 suites / 0 échec, `conductor`
  bumpé v1.26.0.** Les deux arbitrages du 2026-08-17 (points 4 ci-dessus) sont **exécutés** : 3B
  (synchronisation doctrinale complète des 7 fichiers dans 4 modules tiers) et 4A (fermeture du
  trou de la voie legacy du protocole d'acquisition) sont livrés et vérifiés. Fait marquant
  supplémentaire, même leçon de méthode répétée une fois de plus : après les 9 bloquants trouvés au
  **plan** par les vérificateurs externes (ci-dessus), les **trois juges de code** dispatchés sur
  l'implémentation ont trouvé **un bloquant de plus** — le guard tronquait la commande au premier
  `<<`, si bien qu'un heredoc suivi d'un `git commit` passait en silence (motif d'usage courant,
  reproduit). Corrigé au plan 32-03 (troncature heredoc retirée, `32-03-SUMMARY.md` §Traces des
  mutations, tâche 3). Le guard reste **anti-accident, pas anti-adversaire** : `guard-driver-lock.sh`
  couvre les gestes accidentels via Claude Code, jamais un terminal humain direct, un IDE/client git
  tiers, un processus en arrière-plan, un appel MCP, une autre machine, `bash -c`/`eval`, ni une
  session non armée (catégorie C, `32-RELIQUATS.md` §6.2). LOCK-05 est livré comme **convention**,
  pas comme fait observable : aucun commit — y compris ceux de cette phase — ne porte encore le
  trailer `Fence:` à ce jour (`32-RELIQUATS.md` §4 critère 5, §6.4).

- **2026-08-16 — Phase 31 (Manifeste d'install + dry-run, issue #20) livrée — six arbitrages
  D-31-11 à D-31-16, tous nés de re-validations trouvant des défauts qu'une suite verte n'avait pas
  vus.** Détail complet : `31-CONTEXT.md`.

  1. **D-31-11 — `vf_place_tree` : le plan prédit depuis la source, le manifeste consigne la
     destination.** Quatre point-fixes d'affilée sur la même normalisation (copie de répertoire, le
     seul site où « même chemin de code » ne peut pas signifier « même source de données ») ont
     signalé une classe non fermée, fermée par cette distinction explicite.

  2. **D-31-12 — Une garde s'arme au grain unité, pas en attendant que le bout-en-bout l'atteigne.**
     Constat par mutation : la vague 1 ne câblait qu'un site de pose produisant un manifeste d'une
     ligne — remplacer le tri par un `cat`, ou neutraliser les exclusions, laissait la suite verte.

  3. **D-31-13 — Déplacer un appel change sa sémantique d'échec : la tolérance se restaure
     explicitement.** La migration des ~35 sites a réduit des chaînes `a && b && c` (où seule la
     dernière commande déclenche `errexit`) à un appel unique de helper, durcissant des `cp` qui
     toléraient l'échec — quatre régressions bloquantes qu'aucune des trois suites vertes n'avait vues.

  4. **D-31-14 — Le no-op hors cycle est sûr, mais il se dit — une ligne par module, pas par
     chemin.** `vf_manifest_flush` écrase (`mv`) au lieu de fusionner ; `sync` n'ouvre jamais de
     cycle, donc le fichier dérivé n'est candidat à aucune suppression — mais un no-op qui perd une
     information doit rester lisible.

  5. **D-31-15 — Le chemin de suppression résout physiquement, pas textuellement** (arbitrage de
     Samuel), après qu'une revue eut reproduit une suppression HORS `TARGET_ROOT` : `.claude/rules`
     remplacé par un symlink vers un répertoire ANCÊTRE externe, que la résolution textuelle ne
     détectait pas — `vf_rel_to_target` durci en résolution physique (`cd -P`/`pwd -P`).

  6. **D-31-16 — À la désinstallation, ne jamais désenregistrer ce qu'on n'a pas su retirer.** Un
     manifeste imparsable laissait `uninstall` retirer l'entrée du registre en `rc=0` tout en
     laissant les fichiers sur disque (17 → 24, l'écart étant les backups) — désinstallation
     amputée, orphelins sans moyen de les retirer puisque le module n'est plus enregistré.

  **Reste à Samuel, gestes humains gatés** : push de la branche `feat/phase-31-manifeste-dry-run`,
  PR, et release racine (VERSION / plugin.json / marketplace.json intouchés par la phase — module
  `conductor` bumpé v1.25.0, en attente de distribution). MANI-04 n'est pas tenu au sens littéral du
  ROADMAP — `31-ISSUE-20-REPLY.md` est un brouillon sur disque, jamais posté, l'issue #20 jamais
  close (poster/clore sont des gestes humains, ADR-031).

- **2026-08-16 — Phase 30 (Portabilité Windows II) livrée et vérifiée ; branche isolée d'un
  contenu tiers par chirurgie d'historique.** Quatre faits :

  1. **D-01 tranché par Samuel : option A** — chemin absolu **borné** (résolu ET vérifié à
     l'install, `settings.json` devient spécifique à la machine) plutôt que la variante non bornée.
     Gravé dans ADR-071 (§Décision 2) ; amendement LOCK-02 (Phase 32) qui distingue entrée
     distribuée / commande locale posé au commit `57af915` et **toujours présent** sur la branche
     (vérifié : `LOCK-02` cité dans `ROADMAP.md`).

  2. **Cycle rouge → correctif → vert constaté en CI réelle sur PORT-05** — détail complet dans
     `30-08-SUMMARY.md` et l'addendum 2026-08-16 de `30-VERIFICATION.md` : premier push (commit
     `dcd9eb5`) rouge sur le run `31917741411` (attendu codé en dur ne correspondant pas à la
     fermeture réellement installée), correctif (`4edc968`) dérivant l'attendu des `hooks.json` de
     la fermeture résolue à chaque exécution, repoussé et re-éprouvé vert sur le run `31918283177`
     (4 jobs sur 4).

  3. **RFC upstream `open-gsd/gsd-core` déposée** (LEDG-03,
     https://github.com/open-gsd/gsd-core/issues/3556, échéance amont 2026-10-26) — voir l'entrée
     du 2026-08-15 ci-dessous, inchangée.

  4. **8 commits d'une session tierce (spike cockpit-live, Phase 36 roadmap, 2 captures backlog)
     isolés sur la branche `spike/cockpit-live` par chirurgie d'historique**, jamais sur cette
     branche de phase. Preuve machine (re-dérivée, pas recopiée) : `git diff --shortstat 998a531
     193b252 -- .planning/BACKLOG.md .planning/ROADMAP.md .planning/STATE.md .planning/spikes` →
     `8 files changed, 679 deletions(-)`, **0 insertion** — les 4 commits isolés (`9443a56`
     backlog prime-agent, `0952c74` backlog semantica, `218b252` spike-001 VALIDATED, `998a531`
     roadmap Phase 36) et les commits `30-06`/`30-09` légitimes qui les encadraient ont été
     réappliqués sans eux sur `193b252`. L'amendement LOCK-02 (point 1 ci-dessus) et la
     traçabilité D-11 (RFC, point 3) sont **intacts** après la chirurgie — vérifié machine : les
     deux chaînes sont toujours présentes dans `ROADMAP.md`/`STATE.md` sur cette branche.
     **Reste en déviation assumée dans la branche** : le commit `e6c8f8f` (« docs(worktree): #3302
     close COMPLETED — mergé amont, pas releasé, gate Phase 35 inchangé ») — commentaire seul,
     vérifié juste (l'issue amont `open-gsd/gsd-core#3302` est bien close COMPLETED), et il
     **renforce** le gate de la Phase 35 plutôt que de le desservir. Il n'a pas été retiré de la
     chirurgie car il ne porte aucun contenu du spike cockpit.

- 2026-08-15 : **RFC upstream `open-gsd/gsd-core` déposée** (LEDG-03) —
  https://github.com/open-gsd/gsd-core/issues/3556. Demande : rendre optionnelle la suppression
  inconditionnelle de `.planning/REQUIREMENTS.md` à la clôture de jalon (`complete-milestone.md`,
  `git rm` sans flag ni gate). Échéance amont : **2026-10-26**. Brouillon validé par Samuel
  (D-09, AskUserQuestion 2026-08-15) avant post, corps identique bit-à-bit à la version approuvée
  (`30-RFC-UPSTREAM.md`, commit `a3e9fcb`). **Repli si l'amont refuse ou ignore avant l'échéance** :
  la variante réduite locale déjà arbitrée le 2026-07-28 (`STUDY.md`, verdict GO-RÉDUIT, condition
  D3) — un gate local d'absence (`.planning/MILESTONES.md` déclare un jalon clos alors que
  `.planning/REQUIREMENTS.md` est absent) doit alors être intégralement ré-arbitré : soit
  renoncement au gate (doctrine seule, sans machine), soit acceptation assumée d'un gate en conflit
  récurrent avec `complete-milestone` (le moteur continuerait de supprimer le fichier à chaque
  clôture, sans le flag demandé par cette RFC). Ce repli est écrit ici au moment du dépôt, pas
  découvert à l'échéance (Phase 18 n'a pas à re-décider dans l'urgence).

- **2026-08-15 — Phase 29, mission d'équipe sur branche `docs/phase-29-icm-gains` : 12 des 13
  tâches livrées, arrêt propre au checkpoint humain bloquant T-29-05-3.** D-03 (zéro régression
  `dag.sh --scope`) tenue de bout en bout : `dag.sh` et `test-dag.sh` absents du diff de toute la
  branche, baseline 99/99 rejouée à chaque étage. La voie « doctrine seule » établie par 29-01 a
  effectivement permis de livrer G1 sans toucher au socle. **Décision de méthode prise en mission** :
  après 4 défauts consécutifs de la même famille sur `normalize_path()` de `check-map-drift.sh`
  (chacun trouvé par un juge externe, jamais par la suite, chaque correctif fermant le cas nommé
  et laissant survivre son voisin), le budget de 3 tours a été **dépassé délibérément** pour un 4e
  tour changeant de méthode : correction par **point fixe** et preuve de fermeture par **génération**
  (produit cartésien 9 préfixes × 5 corps = 45 combinaisons, 10 rouges avant / 0 après) au lieu
  d'une liste de cas énumérés. Leçon durable : une liste de formes ne ferme jamais une classe
  d'équivalence — seul un test génératif + une propriété d'idempotence le font.
  **Checkpoint T-29-05-3 RENDU le 2026-08-15 (AskUserQuestion, Samuel)** — les 3 points tranchés :
  (1) **gate UTILE**, resserrer 2 bornes *dans les bornes, jamais en filtrant la sortie* — (a) une
  ligne de commande n'est pas un chemin déclaré, (b) `plugin/reference/content/examples/` exclu du
  balayage (cartes volontairement fictives) ; les 3 findings « dossier suivi non cité » (`docs`,
  `manual`, `reports`) restent **légitimes et non corrigés** — c'est le signal assumé. Le gate rend
  désormais exactement ces 3 findings (13 → 3). (2) `docs/_transverse/` **supprimé** — vibeflow-os
  est le repo de distribution, pas un lab, ADR-042 ne s'y applique pas. (3)
  `parallelization.skip_checkpoints` passé à **`false`** : les 3 vecteurs d'auto-approbation de
  checkpoint sont désormais neutralisés (doctrine « checkpoint toujours gaté humain »).
  Registre STRIDE enrichi de `T-29-02-08` (oracle d'existence par traversée `../` en `p2_sens_a` :
  `../` initial mitigé, résidu non-initial accepté `low` — fermeture complète non triviale sous
  ADR-054, qui interdit `realpath`).
  **Reste à Samuel, gestes humains gatés** : push de la branche, PR, et release racine (VERSION /
  plugin.json / marketplace.json intouchés par la phase — 4 modules bumpés en attente de
  distribution : validator v1.3.3, conductor v1.22.0, dev-orchestrator v2.14.0, reference v2.5.3).

- **2026-08-06 — Phase 27, reprise sur arbitrage : les trois gels sont levés, 9 exigences sur 11
  tenues, seul le spike reste à faire en présence de Samuel.** (même mission et même branche
  `feat/phase-27-parallelisation-execution`, PR #35 toujours ouverte et non mergée).
  **Arbitrages de Samuel** : (1) `dag.sh:124` → **RETRAIT** du candidat cwd-relatif, sans ancrage ni
  repli déguisé ; (2) `worktree.baseRef: "head"` → **RATIFIÉ**, prenant effet une fois le fix livré
  et les tests verts ; (3) spike `claude_orchestration` → **ne pas lancer**, présence humaine voulue.
  **Livré** : le vecteur RCE est fermé **dans les deux sites** — `dag.sh` (`4a532ec`) et, après
  balayage repo-wide, `mission-contracts.md` (`08ad030`), où la variante `toplevel` portait le même
  défaut. Fermeture **vérifiée en exécution** (PoC rejoué, plus jamais exécuté) et garde-fou `T33`
  prouvé par **réintroduction réelle du comportement**. Suite : **99 PASS / 0 FAIL** (87 avant).
  **13 agents écrivains armés** en `isolation: worktree`, **0 manager**, lint re-passé par
  répertoire de module (6 répertoires, **25 fichiers réellement lintés**).
  **Trois découvertes de méthode, toutes du même motif — un vert obtenu pour la mauvaise raison** :
  (a) `check-agents.sh` **nu** sort `exit 0` sur « aucun agent dans `.claude/agents` » — il ne scanne
  qu'un répertoire sans récursion, donc valider l'armement avec lui aurait confirmé 13 frontmatters
  en ne regardant **rien** ; (b) un test de mutation **rougissait pour la mauvaise raison** (le
  fixture piège mourait faute de `bash`/`cat` sur le `PATH` restreint et retombait par accident sur
  la valeur attendue) — d'où la règle : exiger la **trace** du rouge, pas le verdict ; (c)
  `git ls-files 'plugin/*/agents/*.md'` rend **49** fichiers là où l'ensemble réel en compte **25**,
  le `*` d'un pathspec git traversant les `/`. **ADR-070** grave la règle générale : une disposition
  `accept` **borne le vecteur qu'elle couvre**, jamais le risque en bloc — c'est ce raisonnement
  non borné (`T-27-01-04`, juste pour `PATH`, faux pour le CWD) qui avait laissé passer la RCE.
  **Doctrine posée** : `team-kernel.md` porte enfin la discipline de commit sous index partagé, avec
  ses **deux moitiés** (jamais `git add` même ciblé, jamais `commit` nu) — elle n'était gravée
  **nulle part** dans la doctrine distribuée, ce qui explique l'écrasement inter-workers du 2026-08-05
  bien mieux qu'une négligence. `mission-contracts.md` §Isolation de branche avait d'ailleurs nommé
  ce trou et l'avait laissé « non tranché ici » ; il est tranché.
  **Reste** : `PAEX-09` (spike) et `PAEX-10` (mesure du gain), tous deux gelés par choix de Samuel.
  `27-04` (baseline d'horloge) est débloqué mais **non capturé** — le `safe_resume_gate` du moteur
  l'avait bloqué tant que `27-03-SUMMARY.md` manquait ; ce SUMMARY est désormais écrit (`183bff7`).

- **2026-08-05 — Phase 27 (parallélisation d'exécution) : vague 1 livrée, phase GELÉE sur
  arbitrage humain** (mission `.planning/missions/2026-08-05-phase-27-parallelisation-execution.md`,
  branche `feat/phase-27-parallelisation-execution`, non mergée). **Livré** : livrable 1 — la
  doctrine fausse de `team-kernel.md:64-65` est corrigée (« perdu » → « **éteint par défaut** »),
  le gate n° 4 (`nested && background`, jamais `backgroundDispatch`) et le verrou pratique
  gate n° 5 (`agent_sdk_version_unknown`) y sont nommés ; livrable 3 — `dag.sh ready` porte un
  champ **additif** `stages` câblé sur `partitionStages()` amont **en sous-processus**, jamais
  réimplémenté (ADR-069, Iron Law 2 révisée), 87 PASS / 0 FAIL contre 71/0 avant ; livrable 2
  **partiel** — `.worktreeinclude` (une seule entrée, `.claude/agent-memory/`) et `.gitignore`
  posés, `27-ISOLATION-PORTEE.md` écrit, mais **0 agent sur 25 armé**. **Trois gels, tous
  ADR-031** : (a) **finding CRITIQUE d'audit, RCE reproduite par PoC** — `dag.sh:124` résout un
  candidat `gsd-tools.cjs` **relatif au CWD** et l'exécute via `node` sans ancrage ; un simple
  fichier tracké suffit, sans symlink ni PATH compromis, dans le socle que les 5 managers
  invoquent en routine. **5ᵉ passage** du motif de confinement de chemin, littéralement prédit par
  `CONCERNS.md`. Non couvert par le threat register : T-27-01-04 n'examinait que `PATH`, dont le
  raisonnement d'acceptation (« un PATH compromis compromet toute la session ») **ne vaut pas**
  pour le CWD. Sur ce dépôt le candidat est une **branche morte** (`gsd-core/` absent de la
  racine) ; (b) tâche 4 de 27-03 (armement des 13 agents écrivains) gatée derrière la
  **ratification** de `worktree.baseRef: "head"` — le réglage a été appliqué hors checkpoint par
  un effet de bord de worker (`.claude/settings.local.json`, gitignoré), donc l'assertion machine
  passe au vert **sans qu'aucun humain n'ait ratifié** ; (c) spike `claude_orchestration` (27-05)
  et mesure post-activation (27-06), checkpoints humains par construction.
  **Deux findings de revue délibérément DIFFÉRÉS avec (a)** : la branche « CLI résolue mais qui
  échoue » n'est pas prouvée (un mutant remplaçant `stages: null` par `stages: []` survit aux 87
  tests, alors que la doctrine livrée interdit cette confusion), et T29 teste une autre branche
  que son commentaire (dépendant de `~/.claude/gsd-core`, donc de l'environnement). Motif du
  report : écrire ces tests avant l'arbitrage graverait comme comportement attendu la branche qui
  pourrait être retirée. **Preuve empirique produite par la phase sur elle-même** : un commit de
  `27-03` a emporté `team-kernel.md`, propriété du plan concurrent `27-02` — un `git add` ciblé
  chez l'un plus un `git commit` sans pathspec chez l'autre suffisent, index partagé. La
  disjonction déclarée gouverne **le dispatch**, jamais **le commit** : seule l'isolation physique
  (`isolation: worktree`) le ferait. **Chiffres re-dérivés** (moteur gsd-core 1.9.1, non épinglable
  — corpus hors dépôt) : ADR-069 tient sur ses deux comptages, `workstream` K2 = **7/91** et
  `.planning/` en dur = **45** ; l'encadré « chiffres divergents » du ROADMAP est levé.

- **2026-08-02 — Le manuel utilisateur (Phase 26) vit sur disque, hors git, et sa disposition
  bilingue est un miroir de dossiers** (mission `.planning/missions/2026-08-01-phase-26-manuel-utilisateur.md`,
  13 décisions D-1..D-13 + point ouvert O-1). Contrainte de Samuel posée en cours de mission :
  **rien sous `manual/` n'est commité**, et **aucune entrée `.gitignore`** — ce fichier étant
  versionné, une entrée y laisserait une trace publique de l'existence du manuel ; l'exclusion
  passe par `.git/info/exclude`. Conséquences : le dégraissage de `README.md`/`README.fr.md`/
  `INSTALL.md` (D-7, D-8) est **gelé** — pointer vers un dossier absent du dépôt casserait les
  liens des visiteurs —, et l'outillage du manuel vit sous `manual/.tools/` plutôt que dans
  `scripts/` + `ci.yml` (D-13), où il aurait à la fois trahi l'existence du manuel et tourné **à
  vide** en CI. Disposition retenue : miroir `manual/fr/` + `manual/en/` (D-1), contre les suffixes
  `.fr.md` de la convention des deux README — **deux panels indépendants ont convergé** : le
  couplage langue↔chemin rend impossible la fuite silencieuse vers l'anglais qu'un `.fr` oublié
  produirait, et réduit la sonde de parité à un `diff` de deux `find`. **Livré : 9 vagues sur 9**
  (44 pages × 2 langues, gate `check-manual` exit 0).

  **Deux points ouverts tranchés par Samuel avant clôture :**

  - **O-1 — slugs anglais sous `manual/en/`** (dossiers ET fichiers : `01-get-started`,
    `07-under-the-hood`, `your-first-lab.md`). La décision **lève l'hypothèse H-1** du `toc.yml`
    (slugs identiques FR/EN), qui rendait le lien miroir déductible du seul chemin. L'appariement
    FR↔EN devient une **donnée explicite** (`id` + `path_fr` + `path_en`) au lieu d'être déduit :
    `build-nav.sh` le lit au lieu de le calculer, `check-manual.sh` C1 compare des identifiants
    logiques et C2 vérifie une bijection par langue. Discrimination re-prouvée par mutation (page EN
    supprimée → C1+C2 rouges ; page EN orpheline → C2 seul rouge, les deux contrôles sont bien
    indépendants). Reliquat soldé dans la foulée : 73 libellés de liens sur 26 pages EN affichaient
    encore des noms de fichiers **français** — les `href` avaient suivi le renommage, pas les
    libellés, ce qui vidait de son sens le renommage lui-même.

  - **Parité de contenu FR/EN — alignement PAR LE HAUT** : les paragraphes présents côté EN
    uniquement sont portés en FR, rien n'est coupé côté anglais. Relevé **re-dérivé du contenu réel**
    (les chemins de la revue étaient périmés depuis O-1) : **31 pages sur 44**, contre 21 estimées —
    l'écart se concentre sur `03-modules`, annoncé à 0/6 et qui en comptait 3/6. Vérifié par un juge
    frais en **couverture intégrale 44/44**, appariement lu dans `toc.yml` : 44/44 OK dans les deux
    sens, français natif sans calque.

  **Volet D-7/D-8 — statut au 2026-08-02** : le blocage a sauté. Samuel a **publié le manuel** (voir
  entrée suivante), donc pointer vers `manual/` ne casse plus rien. Une **mention** est posée en tête
  des deux README. Le **dégraissage complet** des README et d'`INSTALL.md` — le projet d'origine de
  D-7/D-8 — reste **non fait et non demandé** : plus aucun obstacle technique, mais c'est un
  arbitrage éditorial à proposer, pas à décider seul.

- **2026-08-02 — `manual/` devient public : D-14 révoquée** (mission
  `.planning/missions/2026-08-01-phase-26-manuel-utilisateur.md` §3 ter). Renversement, par Samuel,
  de la contrainte qui avait structuré toute la mission. Le manuel entre au dépôt : **94 fichiers**
  (88 pages, 3 index, `toc.yml`, 2 scripts `.tools/`). Ligne `manual/` retirée de
  `.git/info/exclude` ; **rien ajouté à `.gitignore`** — il n'y a plus rien à exclure. Le manuel
  **n'a pas changé d'une ligne** : ce qui le rendait invisible au dépôt était une précaution de
  confidentialité, pas une limite technique, et la mission avait été conduite pour que sa levée soit
  un `git add` et non une reprise. Vérification que la publication rendait enfin possible : les
  **2 liens sortants** du manuel (`../../../docs/ADR.md` depuis les deux pages
  `07-*/…architecture…`) **résolvent** désormais, et **aucun chemin absolu** de la machine de Samuel
  ne traîne dans les 91 fichiers — c'est exactement la classe de défaut qui serait restée invisible
  jusqu'à la publication et cassée pour tout le monde.

- **2026-07-31 — L'anti-triche P12 est garanti par un gate transverse, pas par les suites de
  module** (mission de clôture des reliquats Phase 20, WINDOWS #1). `team-kernel.md:23` affirmait
  que le cloisonnement `disallowedTools` était « vérifié par les suites de test de chaque module » :
  **faux sur pièce** — 0 occurrence de `disallowedTools` dans les suites propres de
  `design-orchestrator`, `business-pilot-bundle`, `content-bundle` et `growth-bundle`, et la seule
  du `dev-orchestrator` est une fixture de `test-inject-mcp-tools.sh`. Arbitrage : **corriger la
  phrase plutôt que dupliquer l'assertion dans 4 suites** — la garantie est transverse par
  construction (un seul gate `check-agents.sh --strict`, passé par la CI sur les 6 dossiers
  `plugin/*/agents` en découverte non vide + monde clos, doublé du hook `guard-agent-write.sh` à
  l'écriture, les deux testés par la suite conductor T69/T70). Quatre copies auraient divergé. La
  faute était de **nommer le mauvais mécanisme**, pas d'avoir un mécanisme manquant.
  **Corollaire non négociable** : la correction de doc seule aurait été un garde-fou inerte (motif
  exact du précédent Phase 19), donc elle est indissociable d'une **assertion sur l'arbre réel** —
  `test-check-agents.sh` T72 balaie `plugin/*/agents/*.md` (découverte dynamique, échec si vide) et
  exige `disallowedTools: Write, Edit` sur tout agent `memory:` + `tools:` sans Write/Edit. Jusque-là
  **aucune** suite du repo n'assertait quoi que ce soit sur les agents réellement posés — tout était
  fixture. Validé par mutation. Commit `8c5f0a5`.

- **2026-07-31 — Deux sessions ont écrit dans `.planning/` en parallèle ; le verrou de driver ne
  l'a pas empêché.** Pendant la mission de clôture des reliquats Phase 20 (verrou tenu par
  `mission-phase21` depuis 15:2xZ), une session tierce a rédigé la **Phase 22** dans `ROADMAP.md` et
  `STATE.md` à 15:37–15:38Z et créé `.planning/phases/VFDO-22-*/`. Confirmation opérationnelle que
  `driver-lock.sh` est **déclaratif, pas contraignant** : il coordonne des missions qui le
  consultent, il n'a aucun moyen d'arrêter un écrivain qui l'ignore. Traitement retenu : le brouillon
  Phase 22 est **préservé verbatim**, jamais réécrit ni annulé, et committé tel quel en signalant son
  origine hors mission. Ne jamais résoudre ce cas par un `stash` ou un `checkout --` décidé seul.

- **2026-07-28 — Un test qui n'exerce pas la commande réellement émise ne teste rien** (mission
  Phase 19, établi par mutation, pas par lecture). Le gap SC3 (`--verify` sans `--force`, garde-fou
  incapable de rendre un verdict en production) a franchi **trois étages de vérification** : revue de
  code PASS, gate de portabilité vert sur 3 OS, audit sécurité 6/6. Il n'a été vu qu'en **mutant le
  bloc livré** — sa suppression complète laissait la suite à 73 OK / 0 KO. Les deux signaux qui
  auraient dû alerter plus tôt sont désormais des sondes explicites : (a) un compte rendu qui prouve
  une **présence** (`grep -c 'verify' → 7`) au lieu d'un comportement ; (b) des cas de test qui
  invoquent une **forme de commande que le chaînage réel n'émet jamais** (`--force --verify` à la
  main, quand la production émettait `--verify` seul). C'est la troisième occurrence du motif
  « test tautologique derrière un décompte vert » sur ce repo (Phase 13 `discover-unintegrated-docs.sh`,
  Phase 17 cas 7, Phase 19 ici) — le contre-poison qui a marché à chaque fois est la **mutation du
  bloc livré**, jamais la relecture.

- **2026-07-28 — Arbitrage de mission (manager, autonomie) : le compteur « N suites » des README
  racine reste rouge à la clôture de phase.** Le gate de portabilité l'avait classé `auto-fix`
  majeur. Refusé : `check-version-sync.sh` est rouge sur ce seul contrôle (41 annoncé vs 42 réel) et
  le rattrapage **voyage avec le commit de release racine**, réservé à validation humaine — patron
  déjà appliqué aux Phases 13 et 17. Le corriger en mission aurait été s'accorder un morceau de la
  release explicitement sortie du périmètre. Les 17 triades par module sont ✓, dont les deux bumps
  de la phase. Corollaire de méthode : un juge frais ignore les déférés qu'on ne lui nomme pas — le
  mandat doit les lui dire, sinon il les remonte en faux positif.

- **2026-07-27 — Arbitrage humain (Samuel) : SC1 de la Phase 17 amendé, la spec fait foi.**
  `.planning/ROADMAP.md` §Phase 17 SC1 disait « les trois scripts sortent en 3 et **aucune ligne**
  n'est injectée […] le coût contexte d'un projet sain est nul ». La spec de référence
  (`docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md` §4.2 et §7) dit l'inverse :
  sur un projet sain, **une** ligne `[gsd-engine]` d'orientation est injectée (« 1 ligne, pas 0 »).
  SC1 tel qu'écrit contredisait aussi SC2 et SC2bis de la **même** entrée ROADMAP, qui exigent ce
  signal (le trou de routage du 2026-07-27 où une demande de conception est partie sur
  `superpowers:brainstorming` alors que le projet tournait sous GSD). Arbitrage retenu par Samuel :
  SC1 devient « les trois scripts sortent en 3 et la **seule** ligne injectée est le `[gsd-engine]`
  d'orientation ». SC2 et SC2bis restent inchangés. **Ceci est un arbitrage humain daté, pas une
  initiative d'agent** — appliqué par `vf-coder` (n1 du DAG de mission Phase 17) sur mandat exprès
  de `vf-dev-manager`, jamais tranché en autonomie.

- **2026-07-27 — Le cloisonnement `Agent(...)` n'est PAS linté par `check-agents.sh`** (mission Phase 15,
  établi empiriquement, pas déduit). Le cadrage de la phase et `team-kernel.md` affirmaient
  « anti-triche machine-enforced, linté par `check-agents.sh` ». Faux : ce script ne teste que la
  *présence* du champ `tools:` (`check-agents.sh:235-236`), jamais son contenu — le frontmatter est
  stocké comme chaîne opaque. Quatre agents fabriqués avec une allowlist de noms inventés, une
  parenthèse non fermée et des outils inexistants passent tous `--strict` en vert, exit 0. Décision :
  l'affirmation a été corrigée partout (`team-kernel.md`, `conductor/README.md`, `mission-cross-team.md`),
  et l'enforcement réel de D-07 passe par les suites de module (T18 dev, T8 design), seule vérification
  machine du contenu de `tools:` dans tout le repo. **Écrire le lint manquant dans `check-agents.sh`
  reste à arbitrer** — extension de périmètre sur un script de gate partagé, non exécutée en mission.
  Piège à connaître si on l'écrit un jour : `general-purpose` est un type natif sans fichier `.md`, et
  les agents `gsd-*` viennent de `@opengsd/gsd-core` — absents d'un lab sans GSD. Un lint exigeant
  `<agents-dir>/<nom>.md` rendrait rouges des allowlists correctes.

- **2026-07-27 — Un recensement de dispatches doit inclure les skills non forkées** (mission Phase 15,
  après deux omissions successives). Aucune skill de `~/.claude/skills/` ne déclare `context:` : aucune
  n'est donc forkée, et chacune exécute ses `Agent()` **dans le contexte de l'agent qui l'invoque**. Un
  manager qui appelle `gsd-ingest-docs`, `gsd-plan-phase`, `gsd-docs-update` ou `gsd-audit-milestone`
  dispatche donc lui-même `gsd-doc-classifier`, `gsd-doc-synthesizer`, `gsd-pattern-mapper`,
  `gsd-integration-checker`… qui doivent figurer dans SON allowlist. Le premier recensement de la
  mission a livré 7 noms, le second 14, un audit indépendant 18. Conséquence de méthode : sur ce type
  d'inventaire, la seconde dérivation doit être **indépendante** (interdiction de lire la première),
  sinon elle recopie l'angle mort au lieu de le corriger.

- **2026-07-27 — Portée réelle de l'interdiction d'imbrication manager→manager** (mission Phase 15).
  Les allowlists des deux managers ferment le chemin de dispatch **direct**. Le chemin **indirect**
  (`manager → worker → manager`) reste ouvert au niveau du dispatch : `vf-coder`, `vf-reviewer` et
  `vf-auditer` portent `Agent` nu. La garantie qu'un seul manager pilote une mission est portée par le
  **verrou de driver**, qui refuse la seconde acquisition quel que soit le chemin (T1 de l'étude,
  `test-driver-lock.sh` T2) — pas par les allowlists. Dette consignée dans `.planning/codebase/CONCERNS.md` ;
  scoper l'accès `Agent` de ces trois workers est une extension de périmètre non exécutée (ADR-031).

- **2026-07-26 — Résolution de `gsd-tools` par CASCADE, jamais par chemin en dur** (mission Phase 11,
  tranchée sur panel de recherche documentaire). Le dossier d'étude prescrivait
  `node "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs"`. Preuve contraire :
  l'installeur gsd-core 1.8.0 gère un scope `--local` qui dépose le payload sous
  `<projet>/.claude/gsd-core/`, or `ensure-deps.sh` dérive justement un `GSD_SCOPE_FLAG`
  `--global`/`--local` — le chemin en dur ratait donc DÉJÀ une population d'utilisateurs que notre
  propre engine sait créer. Forme retenue : l'ordre du snippet officiel amont
  (`_runtime-launcher.snippet.sh`), en variante Claude-only. Corollaires : `gsd-tools` sort exit 0
  même en erreur métier → tester le JSON (`.error`), jamais `$?` ; `VERSION` dérivé du chemin
  résolu ; ne jamais installer `@next` (dist-tag amont périmé : 1.7.0-rc.6 < latest 1.8.0).

- **2026-07-26 — Non-mixité GÉNÉRALE des groupes de hooks** (mission Phase 11, arbitrage manager).
  `merge-hooks.sh` ne fusionne plus jamais les hooks VibeFlow dans un groupe qu'il ne possède pas
  intégralement — y compris un groupe tiers, pas seulement gsd. L'option étroite (restreindre aux
  hooks gsd-managés) aurait affaibli un correctif déjà spécifié ; le risque prouvé (un outil voisin
  qui supprime des ENTRÉES ENTIÈRES) n'est pas propre à gsd-core, et l'invariant est symétrique (à
  la désinstallation, notre `remove` cesse de muter un groupe d'autrui). Conséquence assumée : T2 de
  `test-merge-hooks.sh` a été réécrit — son assertion `len(read_groups)==1` encodait l'ancien
  comportement ; la garantie qu'elle protégeait réellement (anti-prolifération de groupes) est
  conservée explicitement.

- **2026-07-26 — Citation canonique restaurée pour le jalon `vfdo-v1.0`** : la spec
  `2026-06-04-dev-orchestrator-design.md` n'était citée que dans `.planning/phases/01-*/**` (des sorties
  du moteur, pas un registre) — sa citation n'avait jamais été reportée dans le snapshot du jalon à
  l'archivage. C'est `discover-unintegrated-docs.sh` qui l'a mise au jour dès sa première passe sur le
  corpus réel. Confirme le motif déjà connu : **la citation migre puis disparaît à l'archivage**, ce qui
  justifie a posteriori les 6 registres de BRDG-02 plutôt que le seul `ROADMAP.md`.

- **2026-07-26 — Revue de code non négociable sur un fait outillé** : le script de découverte avait été
  livré sans revue (jugée disproportionnée par le worker) avec 12 tests verts. La revue commandée ensuite
  a trouvé **2 bloquants reproduits** (motif de citation non borné à gauche → faux négatif silencieux ;
  échappement ERE partiel → motif absorbant) que la suite ne pouvait pas voir, son cas de bornage étant
  tautologique. Enseignement : sur un artefact à **coût d'erreur asymétrique**, une suite verte ne vaut
  pas une revue — et un test de mutation dit la vérité qu'un décompte de cas cache.

- **2026-07-26 — Phase 13 sans verbe** (arbitrage Samuel) : pas de résurrection de la façade — le pont
  spec → feuille de route est un geste de l'agent `vibeflow-dev`, la découverte seule est outillée
  (ligne de coupe ADR-055 §3).

- **2026-07-25 — Programme d'audit croisé livré en 3 releases** (v2.32.0 → v2.34.0, rapports
  dans `reports/`) : (1) enforcement branché — CI, gates exit 3, scission ADR-031/ADR-056 ;
  (2) **bascule agentique** (arbitrage Samuel, spec
  `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`) — façade vf-* supprimée,
  dev-orchestrator v2.x, manager avec digest/next steps/hygiène doc, gouvernance proportionnée
  au profil ; (3) universalisation — team-kernel transverse (conductor), équipe design,
  content-bundle matérialisé `proposable:true`, pipelining N/N+1, lab express, ADR-057.
  Prolongé par **v2.35.0** : growth-bundle et business-pilot-bundle matérialisés à leur tour
  (quality-gate-client livré) — les 3 bundles métier sont réels, promesse multi-métier tenue.
  **v2.36.0** : recettes UAT réelles sur labs vierges (express ~11 min 30 ✓ ; protocole de
  mission exécutable par un agent tiers ✓) — 16 frictions corrigées, job CI « lab frais »
  (la baseline doit passer ses propres gates depuis un lab vierge).

- [Phase 1]: D4 — index 100% auto-généré, ordre pipeline documenté dans l'agent.
- [Phase 1]: D3 — install auto des deps, init projet sur confirmation seulement.
- [Phase ?]: Index GSD trié alphabétiquement pour diff déterministe + idempotence vérifiable (Plan 01-01)
- [Phase ?]: [Phase 1]: ensure-deps.sh utilise set -uo pipefail (sans -e) car les détections reposent sur des exit non-zéro normaux (Plan 01-02)
- [Phase ?]: [Phase 1]: Contrat de test VF_ENSURE_DRY_RUN=1 pour valider l'idempotence sans réseau (Plan 01-02)
- [Phase ?]: [Phase 1]: Modules AGENT — references sous .claude/agents/<mod>-references/ (D7), index régénéré à l'install via VF_INDEX_OUT (IDX-02) (Plan 01-05)
- [Phase ?]: [Phase 1]: Densité des .md mesurée par wc -l, jamais le contrôleur de taille générique qui ignore les .md (Plan 01-05)
- [Phase ?]: module.json: requires[] = prérequis module réels uniquement, ENGINE (vibeflow-update.sh) exclu
- [Phase ?]: Engine défaut LEGACY=project (rétro-compat ./.claude) ; skill /vibeflow-install passe toujours VF_SCOPE explicite (cohérence ID4)
- [Phase ?]: docs/<mod>/ doc-only laissé hors TARGET_ROOT (relatif au cwd projet)
- [Phase ?]: Plus de git clone/pull : source = cache local (require_cache) ; sync = no-op explicite
- [Phase ?]: ensure-deps scope-aware via VF_SCOPE (GSD --global/--local, Superpowers --scope), VF_ENSURE_FORCE dry-run only, defaut LEGACY user (ID4)
- [Phase ?]: Hook VibeFlow pointe directement le script bash; marqueur 1er lancement aligné sur registre engine scripts/.vibeflow-installed
- [Phase 06]: Garde-fou first-use placé avant la table de routage (point de décision router-vs-proposer)
- [Phase 06]: Séquence d'init non dupliquée : délégation au skill vf-init existant
- [Phase ?]: 19-02: capture de l'état legacy avant toute garde de ensure_gsd() (D-08.3), preuve directe par T2k
- [Phase ?]: 19-02: npm_pkg_installed_globally() est le seul appel npm réellement exécuté (lecture seule), --verify d'inject-mcp-tools.sh ne rejoue jamais --force
- [Phase ?]: 2026-07-31 — Phase 20 (20-07, clôture) : anti-triche « vérifié par les suites de test de chaque module » constaté FAUX pour design-orchestrator/business-pilot-bundle/content-bundle/growth-bundle (0 test de disallowedTools dans leur suite propre) — inscrit en différé nommé (WINDOWS.md), non corrigé (P-07).
- [Phase ?]: 2026-07-31 — Phase 20 (20-07) : compteurs du module obligatoire écrits à leur valeur réelle (14 scripts, 12 suites, pas 11) — un correctif de revue hors plan (test-guard-agent-write.sh, commit 447e75a) a créé une 2e suite entre le cadrage et l'exécution. Compteur repo-entier de suites réel = 44, pas 43 : consigné en reste-à-faire de release racine.

### Pending Todos

- **Release de clôture du milestone `vf-routing`** (bump `VERSION` racine + `plugin.json` +
  `marketplace.json` + historique des 2 README, puis tag annoté poussé, `check-release-tag.sh --remote`
  → ✓). Le module `dev-orchestrator` est déjà en v2.2.0 ; la racine est restée en v2.36.2.
  **Réservée à validation humaine — non faite en mission.**

- **Recette humaine de la Phase 19 (SC2)** : parcours `/vf-update` sur un poste réellement legacy —
  vérifier que la ligne « moteur GSD legacy 1.42.3 → `@opengsd/gsd-core` » apparaît **avant** tout
  stop sur « plugin à jour », puis l'**accepter** (migration + ré-injection MCP enchaînées) et, sur
  un second passage, la **refuser** (aucun effet de bord, aucune insistance). Seul critère de la
  phase non éprouvable par test — c'est du comportement d'agent.

- **Arbitrage à trancher (remonté par la mission Phase 19, non tranché seul)** : les vagues
  parallèles d'exécution partagent le même arbre de travail (pas d'`isolation: worktree`). Aucune
  collision constatée — les périmètres de fichiers étaient disjoints et déclarés — mais la garantie
  vient de la déclaration, pas de la construction. Même famille que l'incident de verrou de la
  Phase 16.

- **Arbitrage doctrinal (audit BRDG-03)** : la confirmation humaine ADR-031 avant ingestion est ancrée
  à `vibeflow-dev` seul. `vf-dev-manager` (chemin équipe, qui consulte `intent-routing.md` pour mapper
  un brief brut) n'a **aucune ligne nominative** sur l'ingestion, contrairement au patron déjà appliqué
  aux skills de clôture de milestone (« en respectant leurs confirmations internes »). Deux filets
  génériques couvrent probablement le cas, mais rien ne l'interdit noir sur blanc. Options : (a) no-op
  assumé, (b) ligne miroir dans `agents/vf-dev-manager.md` renvoyant à `ingestion-flow.md`.

- Combler le trou de couverture du **filtre glob** de `discover-unintegrated-docs.sh` : le mutant
  « filtre retiré » survit à la suite (16 ok quand même). Effet possible = faux négatif, jamais faux
  positif — donc pas de ré-ingestion silencieuse, priorité basse.

- ~~Divergence lexique P3-P8~~ **tranchée le 2026-07-26** (commit b835ffd) : le Core v4.2 est
  canonique, lexique réaligné, module reference v2.5.2 — part avec la prochaine release.

- *(milestone `gsd-migration`)* Mission Phase 11 dispatchée (vf-dev-manager) sur les 6 vagues de
  `10-APPROFONDISSEMENT.md` §5 — release finale réservée à validation humaine.

### Blockers/Concerns

- **Phase 23 — 7 arbitrages humains en attente, la phase est GELÉE derrière eux** (mission du
  2026-08-02). Le nœud `exec-01` est livré et gaté ; `revue-01` est `ready` mais non re-dispatché
  (budget de boucle atteint). Les plans 23-02 à 23-08 restent `blocked`. Quatre décisions portent
  sur la **doctrine** (fichiers gelés `mission-contracts.md`, `mission-flow.md`, `vf-coder.md`,
  `vf-dev-manager.md`) : D-02 inerte (le désarmement du flag d'enchaînement crée la condition de son
  propre ré-armement) · `workflow.auto_advance` jamais désarmé · le minimum de reprise ne transporte
  pas la **réponse** humaine (boucle sur un gate `blocking-human`) · geler le nœud **ou** poser la
  question, en mode autonome. Trois portent sur la **couverture de test** : rc=3 contraint la forme
  rédactionnelle · porosité assumée de T25 · déclassement de T26 A′. Détail et options :
  `.planning/missions/2026-08-02-phase-23-couplage-gsd.md`.

- Migration package GSD `get-shit-done-cc` → `@opengsd/gsd-core` : milestone `gsd-migration` (VOC-02),
  ouvert et **en attente** — non bloquant pour vf-routing. Le go/no-go de la Phase 10 dépend de la
  maturité/parité du package cible sur npm — à vérifier en premier.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260801-17w | Isolation multi-session : un écrivain = un worktree (ADR-064) + gate advisory de revendication de branche | 2026-08-01 | `efa20c5` | [260801-17w-isolation-multi-session](./quick/260801-17w-isolation-multi-session/) |
| 260804-ki4 | Invalider et re-régénérer le cache du bandeau update après /vf-update (vf-update-run.sh) — conductor v1.19.2 | 2026-08-04 | `e4a6138` | [260804-ki4-invalider-et-re-r-g-n-rer-le-cache-du-ba](./quick/260804-ki4-invalider-et-re-r-g-n-rer-le-cache-du-ba/) |
| 260810-fh3 | ensure-design-deps.sh : présence ET activation des 4 plugins de la chaîne design, auto-install non-interactif, câblage engine + agent — design-orchestrator v1.5.0 | 2026-08-10 | `e9b3650` | [260810-fh3-doter-design-orchestrator-d-un-ensure-de](./quick/260810-fh3-doter-design-orchestrator-d-un-ensure-de/) |
| 260815-tl6 | Snapshot hebdo traffic/clones GitHub (script + workflow cron + branche traffic-data) avec clones ajustés hors jobs CI | 2026-08-15 | `73363c1` | [260815-tl6-snapshot-hebdo-traffic-clones-github-ave](./quick/260815-tl6-snapshot-hebdo-traffic-clones-github-ave/) |
| 260815-wnk | Capture étude « AI Agents in Depth » × VibeFlow (rapport recherche + entrée backlog milestone candidat) | 2026-08-15 | `f920b09` | [260815-wnk-capture-etude-ai-agent-book](./quick/260815-wnk-capture-etude-ai-agent-book/) |

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Recette humaine | **WINDOWS #3** — valider `test_sim` / `build_sim` / `clean` (clé `vf-mcp-tools`) contre un serveur **XcodeBuildMCP vivant** sur un lab iOS équipé. Reste `open` : **infaisable dans ce dépôt** (aucun `.mcp.json`, serveur non connecté) — toute preuve produite ici serait fabriquée. Se recette sur `RoastMyRoom` ou `FreelanceMoneyCalc`, pas sur `vibeflow-os`. | open | 2026-07-31 |
| Geste humain | **Snapshot traffic NON ACTIVÉ** (quick 260815-tl6) — le workflow `.github/workflows/traffic-snapshot.yml` est livré mais dormant : il manque le secret dépôt `TRAFFIC_PAT` (PAT fine-grained limité à picmakpro/vibeflow-os, permissions Administration: read + Metadata: read). Tant qu'il manque, les runs cron sortent en vert « non activé » sans rien faire. Activation = poser le secret (marche à suivre dans l'en-tête du workflow) + un `workflow_dispatch` pour amorcer la branche `traffic-data`. | open | 2026-08-15 |
| Dette outillage | **WINDOWS #4** — `inject-mcp-tools.sh` ne valide pas qu'un nom de serveur cité dans un token `vf-mcp-tools`/`mcp__` **existe réellement**. **Repris au périmètre de la Phase 21, changement 1** : la phase rouvre déjà ce script pour lui donner la découverte des serveurs en scope global (`~/.claude.json`) — une fois la source des noms de serveurs connue du script, valider un nom cité devient possible, alors que c'était structurellement hors de portée tant que la seule source était `./.mcp.json`. | repris en Phase 21 | 2026-07-31 |

## Session Continuity

**Resume file:** .planning/phases/VFDO-31-manifeste-d-install-dry-run-issue-20/31-CONTEXT.md

Last session: 2026-08-16T00:00:00.000Z
Stopped at: Phase 31 livrée (8 plans, 6 vagues) — hygiène documentaire de clôture posée
Reprendre par : gestes humains gatés — push de la branche `feat/phase-31-manifeste-dry-run`, PR,
puis cadrage de la Phase 32 (Durcissement du driver-lock), qui dépend de la forme exec des hooks
livrée en Phase 30 et ne touche que `conductor`.
