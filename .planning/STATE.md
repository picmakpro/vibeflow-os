---
gsd_state_version: 1.0
milestone: gsd-migration
milestone_name: Migration package GSD
current_phase: 19
current_phase_name: Migration du moteur GSD pilotée par /vf-update — planifiée (3 plans), 19-01, 19-02 et 19-03 exécutés
status: in_progress
stopped_at: "Plan 19-03 exécuté le 2026-07-28 — vf-update/SKILL.md : diagnostic à deux volets (sonde check-gsd-engine.sh consultée AVANT le stop sur plugin à jour), ligne de confirmation moteur indépendante, §Garde-fous réécrit ; ADR-058 posé ; release-meta dev-orchestrator v2.7.0 + conductor v1.16.0. check-version-sync.sh rouge uniquement sur le compteur de suites des 2 README racine (41 vs 42 réel), reste-à-faire nommé pour le commit de release humain. Phase 19 (3/3 plans) prête pour clôture."
last_updated: "2026-07-28T13:00:00.000Z"
last_activity: 2026-07-28 (exécution Phase 19 Plan 03 — vf-update/SKILL.md, ADR-058, release-meta)
progress:
  total_phases: 19
  completed_phases: 10
  total_plans: 53
  completed_plans: 37
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-26 — charte rouverte : 17 modules, D2/D6 renversées)

**Core value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.
**Current focus:** Phase 17 **terminée et vérifiée, NON shippée** (2026-07-28) — signaux de démarrage
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

Phase: 17 **complète — vérifiée, release racine en attente** (VERSION racine intouchée : 2.41.0)
Signaux de démarrage du moteur de dev. Livrée en mission d'équipe (DAG à 5 nœuds : n1 cadrage+plan ·
n2 exécution · n3 gate portabilité · n4 audit advisory/read-only · un `reopen` unique après fusion des
deux juges · n5 clôture, `.planning/missions/dag-phase17.json`). Livré : `check-dev-bootstrap.sh`
(continuum à 4 états), `check-doc-drift.sh`, `discover-unintegrated-docs.sh --hook`,
`hooks/hooks.json`, section *Signaux de démarrage* dans `AGENT.md`, 2 nouvelles suites de tests.
Module `dev-orchestrator` **v2.6.0** (collision de version résolue : la Phase 16 concurrente avait
déjà pris v2.5.0, cible ajustée à v2.6.0 — commit `5a8b6a8`).
Status: Terminée et vérifiée, non shippée.
Last activity: 2026-07-28 (clôture Phase 17)

**SC5 (advisory / lecture seule) — CONFORME.** Prouvé par exécution, pas par lecture : lecture seule
OUI (seul `mktemp` de `discover-unintegrated-docs.sh:91-93`, apparié au `trap ... EXIT` ligne 94, borné
à `$TMPDIR`) · aucun `exit 1` OUI (seuls 0/3/64 ; `set -uo pipefail`, pas de `set -e`) · aucun blocage
de tour OUI (`hooks.json` = un seul groupe `SessionStart`, 3 commandes chacune suffixée `|| true`,
aucun `Stop`/`PreToolUse`). Robustesse : 5 fixtures de frontmatter hostiles (injection shell, octet de
contrôle 0x01, délimiteur tronqué, `$(whoami)`) → stdout VIDE et exit 3 dans les 5 cas ; `node_modules`
de 20 000 fichiers → 0.007s (élagage `-prune` confirmé) ; hors dépôt git sur chemin à espace/UTF-8 →
silence propre. Toutes les menaces `high` du threat model closes.

**SC6 (portabilité macOS ET Linux) — PROUVÉ.** Compteurs **identiques** sur trois environnements :
macOS bash 3.2.57, Debian 12 bash 5.2.15, Ubuntu 24.04 bash 5.2.21 (OS exact de
`runs-on: ubuntu-latest`) → `test-check-dev-bootstrap.sh` 23 ok/0 ko · `test-check-doc-drift.sh` 21
ok/0 ko · `test-discover-unintegrated-docs.sh` 22 ok/0 ko. Aucun test sauté silencieusement. Zéro
piège BSD/GNU trouvé. Aucun edit de `ci.yml` nécessaire.

**Comblement post-exécution** (commit `6e33b14`, après fusion des verdicts n3/n4) : cas 7 de
`test-discover-unintegrated-docs.sh` rendu discriminant (il était tautologique : vert avec ou sans le
filtre glob — prouvé par mutation, 21 ok/1 ko après retrait du filtre) ; boucle T21 de
`test-dev-orchestrator.sh` élargie à `discover-unintegrated-docs.sh`, seul des 3 scripts à utiliser
`mktemp`.

**Deux dettes inscrites à `CONCERNS.md`** (constatées pendant la mission, pas corrigées — hors
mandat de clôture) : le verrou de driver n'empêche techniquement rien (déclaratif, pas contraignant —
la Phase 16 a continué à commiter pendant que la Phase 17 tenait le verrou) ; le gate ADR-044 est un
faux vert dans son invocation nue prescrite par la spec (`check-agents.sh` sans argument sort exit 0
sans rien vérifier, `.claude/agents` étant absent de ce repo).

**Réservé à validation humaine** : release de clôture (bump `VERSION`/`plugin.json`/`marketplace.json`

+ historique des 2 README, tag annoté poussé, release GitHub, `check-release-tag.sh --remote` → ✓).

Pré-requis identifié : `scripts/check-version-sync.sh` est actuellement **rouge** — `README.md` et
`README.fr.md` annoncent « 39 suites » contre 41 réelles (les 2 suites ajoutées par cette phase), à
corriger avant tout bump.

---

Phase: 16 **complète — shippée `v2.41.0`** (tag annoté + release GitHub, `check-release-tag --remote` ✓)
Cloisonnement complet des dispatches. Livrée en mission d'équipe le 2026-07-27, en autonomie complète
(cadrage rétroactif, aucun checkpoint humain). **4/4 Success Criteria tenus**, SC3 amendé (voir plus
bas). Suites rejouées à la main avant release : 58 check-agents · 51 dev · 12 design ·
`check-version-sync` ✓ · 6/6 modules `--strict` exit 0 · 6/6 en monde fermé (`--resolve-agents=strict`,
le job CI). Modules : `conductor` v1.15.0 · `dev-orchestrator` v2.5.0.
Status: Shippée.
Last activity: 2026-07-27 (mission d'équipe Phase 16 + release v2.41.0)

**Amendement SC3 — une allowlist `Agent(...)` n'est pas un sandbox runtime.** Découverte de la
mission, doc officielle citée verbatim dans l'en-tête de `check-agents.sh` : le runtime **ignore** la
liste de noms entre parenthèses dans la définition d'un sous-agent ; seule la présence de
`Agent`/`Task` dans `tools:` compte pour lui. L'allowlist n'est une vraie restriction runtime que
pour un agent incarné en thread principal (`claude --agent`). Elle reste donc un **contrat documenté,
enforcé par le lint et par lui seul** — ce qui vaut rétroactivement pour les allowlists des deux
managers posées en Phase 15. Le cloisonnement est réel, mais c'est un gate machine, pas un bac à sable.

**Deux dettes fermées** (retirées de `CONCERNS.md`) : accès `Agent` non scopé des 3 workers, et
`check-agents --strict` sans périmètre tiers (les 66 faux positifs du scope user, réglés par
`--third-party-prefix` et vérifiés empiriquement sur `~/.claude/agents`).

**Incident de concurrence à traiter — verrou de driver expiré en cours de mission.** Le TTL est de
30 min ; plusieurs workers ont tourné 10 à 22 min et les heartbeats du manager étaient placés *entre*
les frontières de dispatch, jamais pendant. Le lock a expiré, la session concurrente (Phase 17) l'a
récupéré, et le `release` final du manager Phase 16 a rendu `not-owner`. **Deux managers ont donc
tourné en parallèle** — sans dégât ici parce que les périmètres étaient disjoints, mais par chance,
pas par construction. L'invariant « un seul driver » n'est pas tenu face à des workers plus longs que
le TTL. À instruire (candidat phase ou correctif kernel : heartbeat pendant l'attente d'un worker,
ou TTL indexé sur la durée réelle des dispatches).

---

Phase: 13 **complète — shippée `v2.37.0`** — milestone vf-routing CLOS
Plans: 13-01 ✅ (découverte outillée, BRDG-02) · 13-02 ✅ (câblage agent, BRDG-01/BRDG-03).
Vérification goal-backward **PASS** (`13-VERIFICATION.md`) : 4/4 critères dans le mandat, 3/3 BRDG,
22/22 must-haves, 0 blocker. Suites : 16 ok · 30 OK/0 KO · 10 OK · check-agents ✓ · check-version-sync ✓.
Module `dev-orchestrator` bumpé **v2.2.0** ; `VERSION` racine volontairement **intouchée** (v2.36.2).
Status: Milestone clos — release `v2.37.0` publiée et taggée le 2026-07-26.
Last activity: 2026-07-26 (mission d'équipe : exécution complète de la Phase 13)

**Phases 12 et 14 livrées et publiées sur `main`** :

- Phase 12 (Routage fin & verbes `/vf-*`) — 6/6 plans · release **`v2.31.0`**. Livrait 31 verbes et la
  rule de préséance ; **la façade `/vf-*` a été supprimée depuis en v2.33.0** (bascule agentique, spec
  `2026-07-25-suppression-facade-vf-design.md`) — subsistent la carte d'intention unique de
  `vibeflow-dev` et les skills `vf-auto` / `vf-dev`.

- Phase 14 (Frontière d'altitude `planning-core` / moteur GSD) — 7/7 plans · release **`v2.30.0`** ·
  **ADR-055** (renuméroté au merge : `ADR-054` était déjà pris par la portabilité Windows publiée en
  v2.29.0). 92 assertions vertes.

**Depuis la clôture des phases 12/14, 5 releases hors milestone** (v2.32.0 → v2.36.1) : enforcement CI,
bascule agentique, team-kernel transverse, 3 bundles métier matérialisés, recettes UAT, refonte README.
Versions modules au 2026-07-26 : dev-orchestrator v2.1.1 · design-orchestrator v1.2.1 ·
conductor v1.14.1 · planning-core v2.5.1 · consolidator v1.8.0.

Milestone `gsd-migration` (Phases 10-11) reste ouvert et **en attente** — chantier indépendant, non bloquant.
Milestone précédent memory-swarm-rnd **SHIPPÉ v2.28.0** (ADR-052 mémoire vivante + ADR-053 swarm).

Progress: [██████████] 3/3 phases — SHIPPED `v2.37.0`

## Performance Metrics

**Velocity:**

- Total plans completed: 26+ (13 mesurés phases 1-6 ci-dessous + 6 en Phase 12 + 7 en Phase 14 ;
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
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase VFDO-19 P02 | 90min | 3 tasks | 4 files |

## Accumulated Context

### Roadmap Evolution

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

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (D1–D6).
Recent decisions affecting current work:

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

### Pending Todos

- **Release de clôture du milestone `vf-routing`** (bump `VERSION` racine + `plugin.json` +
  `marketplace.json` + historique des 2 README, puis tag annoté poussé, `check-release-tag.sh --remote`
  → ✓). Le module `dev-orchestrator` est déjà en v2.2.0 ; la racine est restée en v2.36.2.
  **Réservée à validation humaine — non faite en mission.**

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

- Migration package GSD `get-shit-done-cc` → `@opengsd/gsd-core` : milestone `gsd-migration` (VOC-02),
  ouvert et **en attente** — non bloquant pour vf-routing. Le go/no-go de la Phase 10 dépend de la
  maturité/parité du package cible sur npm — à vérifier en premier.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

**Resume file:** None

Last session: 2026-07-28T13:00:00.000Z
Stopped at: Completed VFDO-19-03-PLAN.md
ubuntu:24.04) — 3 jobs verts au run 30257419335. Modules bumpés : conductor v1.14.5,
consolidator v1.8.1, dev-orchestrator v2.3.2. Leçon durable : tout bash développé sur macOS/BSD
doit être reproduit sous `docker run ubuntu:24.04` avant push (stat/-f, TMPDIR, outillage hôte).
Reprendre par : **release patch v2.39.1** (décision humaine — distribue les fixes aux labs, dont
le vol de lock ABA), et l'arbitrage engine sur les templates-memoire jamais posés à l'install.
