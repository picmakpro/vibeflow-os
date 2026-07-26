# Requirements: VibeFlow Dev Orchestrator (VFDO)

**Defined:** 2026-06-04
**Core Value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.

## v1 Requirements

### Routing & Agent

- [x] **ROUT-01**: L'agent `vibeflow-dev` route ≥11 intentions en langage naturel vers le bon skill GSD/superpowers (table de routage).
- [x] **ROUT-02**: L'agent embarque l'ordre canonique du pipeline GSD + bonnes pratiques (détail dans `references/GSD-PIPELINE.md`, chargé on-demand).
- [x] **ROUT-03**: L'agent ne nomme jamais « GSD » à l'utilisateur et reframe les sorties en vocabulaire VibeFlow.
- [x] **ROUT-04**: L'agent est distribué via `AGENT.md` et installé en `.claude/agents/dev-orchestrator.md` par `vibeflow-update.sh`.

### Index GSD

- [x] **IDX-01**: `build-gsd-index.sh` parse les `SKILL.md` des skills `gsd-*` installés → `references/gsd-skills-index.md` (factuel uniquement, aucun nom inventé).
- [x] **IDX-02**: L'index se régénère à l'install/update du module et lors d'un drift GSD détecté.

### Abstraction

- [x] **ABS-01**: Un set complet de commandes `/vf-*` mappe vers GSD/superpowers/bootstrap, invocables par l'utilisateur ET par l'agent en autonomie.
- [x] **ABS-02**: Une traduction de vocabulaire masque les termes GSD (ex. « SUMMARY » → « rapport de sprint »).

### Bootstrap auto-install

- [x] **BOOT-01**: `ensure-deps.sh` installe GSD en non-interactif si absent (`npx -y get-shit-done-cc@latest --claude --global`).
- [x] **BOOT-02**: `ensure-deps.sh` installe Superpowers en non-interactif si absent (`claude plugin install superpowers@claude-plugins-official --scope user`).
- [x] **BOOT-03**: `ensure-deps.sh` est idempotent, vérifie les exit codes, et affiche les étapes manuelles uniquement si un prérequis (Node/npm ou CLI `claude`) manque.
- [x] **BOOT-04**: `gsd-new-project` (interactif) ne se lance jamais seul ; l'agent propose l'init sur confirmation ; `map-codebase` peut tourner auto si du code existe.

### Vérification

- [x] **VERIF-01**: `tests/test-dev-orchestrator.sh` couvre génération d'index, idempotence de `ensure-deps`, couverture du routage, mapping `/vf-*` non orphelin.
- [x] **VERIF-02**: Gates de densité respectés (agent ≤250L, skills ≤500L), vérifiés par `wc -l` dans le test du module (`check-file-size.sh` n'audite pas les `.md` : regex code sans `.md`).

## Milestone 2 — Install UX (shipped `v2.4.0`, 2026-06-05)

> Spec : `docs/superpowers/specs/2026-06-04-install-ux-design.md`

### Manifeste & résolveur (Phase 2)

- [x] **MANIF-01**: Chaque module a un `module.json` (name, version, type, description, `requires[]`) — source machine-lisible.
- [x] **MANIF-02**: Un résolveur calcule la fermeture transitive des `requires` (ex. validator → consolidator + infrastructure-audit).

### Engine scope-aware (Phase 3)

- [x] **SCOPE-01**: `vibeflow-update.sh` accepte `--scope user|project|local` → résout `TARGET_ROOT` (`~/.claude` vs `./.claude`).
- [x] **SCOPE-02**: Source des modules = cache du plugin (plus de `git clone .vibeflow-cache`).
- [x] **SCOPE-03**: `ensure-deps.sh` scopé : GSD `--global`/`--local`, Superpowers `--scope user|project|local`.
- [x] **SCOPE-04**: Scope `local` → ajout des chemins installés au `.gitignore`.

### Skill /vibeflow-install + auto-lancement (Phase 4)

- [x] **INST-01**: Toggle scope (single-select user/project/local).
- [x] **INST-02**: Toggle modules (multi-select) avec description issue des `module.json`.
- [x] **INST-03**: Récap des dépendances auto-résolues avant install.
- [x] **INST-04**: Orchestration de l'install au scope choisi (modules + GSD + Superpowers).
- [x] **INST-05**: Hook `SessionStart` + marqueur de 1er lancement → ouvre l'UX automatiquement (ID8).

### Packaging plugin (Phase 5)

- [x] **PLUG-01**: `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` valides.
- [x] **PLUG-02**: Le plugin bundle modules + skill + engine + manifeste.
- [x] **PLUG-03**: Repo `vibeflow-os` rendu public (étape délibérée confirmée).
- [x] **PLUG-04**: `claude plugin marketplace add` + `install` fonctionnent en zéro-auth (validé).

### dev-orchestrator first-use (Phase 6)

- [x] **FIRST-01**: L'agent détecte l'absence de `.planning/` (projet non GSD-initialisé) au 1er usage.
- [x] **FIRST-02**: Il propose map-codebase puis new-project sur confirmation (jamais `gsd-new-project` seul).

## Milestone 3 — Doctrine dev & consolidation (shipped `v2.20.0`, 2026-07-07)

> Spec : `docs/superpowers/specs/2026-07-07-dev-doctrine-consolidation-design.md`
> Origine : audit du parc de modules vs `dev-orchestrator`.

### Philosophies de dev (Phase 7)

- [x] **PHIL-01**: `software-architecture/references/principles.md` existe et porte **DRY** comme contrat vérifiable (test → signal → remède), distinct de « dry-run ».
- [x] **PHIL-02**: `principles.md` porte **KISS** et **YAGNI** (frères de DRY, même format).
- [x] **PHIL-03**: **Clean Architecture** est nommée en place dans `solid-soc.md` (section couches = Dependency Rule).
- [x] **PHIL-04**: **Clean Code** est nommée en place dans `solid-soc.md` (petites unités, `Result<T>`, contrats typés).
- [x] **PHIL-05**: Une **carte TDD** (Red-Green-Refactor + quand l'appliquer) renvoie au skill canonique `superpowers:test-driven-development` / `tdd` et s'articule au Gate Nyquist — sans dupliquer la mécanique (DD3).
- [x] **PHIL-06**: `SKILL.md` câble DRY/KISS-YAGNI/Clean Code en **Tier 2** (audit de sprint), ajoute une ligne TDD en Tier 1, référence `principles.md`, et étend le frontmatter `description`. Aucun faux gate machine (DD4).
- [x] **PHIL-07**: `universal-vs-dev.md` étend la table universelle avec DRY/KISS/YAGNI (transposition non-dev).
- [x] **PHIL-08**: `software-architecture` : `module.json` (description + bump v1.2.0) + CHANGELOG + README mis à jour ; densité `.md` sous seuils ADR-029.

### Consolidation des doublons (Phase 8)

- [x] **CONS-01**: Un seul foyer de rule de gates de code — `feature-dev-gates` fusionné dans `software-architecture` (ou déprécié avec plan de migration), plus de doublon de globs.
- [x] **CONS-02**: `audit-architecture` renvoie aux modules au lieu de dupliquer (Instance C `examples-cross-domain.md:44-61`) ; sa `module.json` legacy corrigée.
- [x] **CONS-03**: Les 3 axiomes (enforcement>prose, filet fonctionnel, preuve avant done) ont une source unique + renvois.
- [x] **CONS-04**: Invariant vérifié — `dev-orchestrator` reste un pur routeur, aucune doctrine injectée (DD1).

### R&D mémoire & swarm (Phase 9)

> Spike **R&D hors chaîne de release** — décision go/no-go, aucun changement du format mémoire officiel ni du
> socle `conductor` sans ADR. Source : `.planning/research/jcode-memory-swarm-transposition-NOTE.md` (§0–5).

- [x] **RND-01**: Le frontmatter mémoire enrichi (3 gestes — `trust` high/medium/low, `confidence` 0–1 +
  règle de **décroissance par catégorie**, `superseded_by` non destructif) est prototypé sur ≥1 lab témoin et
  le `consolidator` sait le tenir à jour **automatiquement** : round-trip lit→recalcule→réécrit sans édition
  humaine, ET une entrée `superseded_by` archivée (statut basculé, contenu conservé — pas supprimée). Sinon →
  no-go documenté avec la raison.
- [x] **RND-02**: Une **note go/no-go écrite** tranche (a) écrire un ADR + toucher le format officiel, ou (b)
  archiver — avec les demi-vies de décroissance **re-calibrées** pour l'usage VibeFlow multi-métiers (pas les
  valeurs jcode brutes), ET un **mini-cadrage écrit du volet swarm** (lock de driver unique RAII + DAG
  ready/blocked), **non implémenté** tant que des collisions ne sont pas observées (ADR-048/049).

## Milestone gsd-migration — Migration package GSD (VOC-02)

### Phase 10 — Étude & faisabilité

- [x] **GSDM-01** *(2026-07-26 — `10-ETUDE.md` §1)*: La surface d'usage GSD dans VibeFlow est inventoriée exhaustivement — chaque point de
  contact (`ensure-deps.sh`, `build-gsd-index.sh`, binaire `gsd-sdk`, chemins `~/.claude/get-shit-done/`,
  pins `PROJECT.md`, hooks, références docs) listé avec le changement attendu.
- [x] **GSDM-02** *(2026-07-26 — `10-ETUDE.md` §2, sourcé npm/GitHub/tarball)*: Le package cible `@opengsd/gsd-core` est caractérisé — existence/stabilité npm, commande
  d'install non-interactive équivalente, nom du binaire, structure de dossier, parité fonctionnelle des
  skills/SDK consommés ; écarts documentés.
- [~] **GSDM-03** *(note écrite `10-ETUDE.md` §5 — recommandation GO, validation humaine du GO en attente pour ouvrir la Phase 11)*: Une note go/no-go écrite tranche — (a) migrer maintenant (stratégie + fenêtre de compat),
  (b) attendre (déclencheur de resurgence explicite), ou (c) archiver.

### Phase 11 — Intégration (conditionnée au GO de la Phase 10)

- [ ] **GSDM-04**: `ensure-deps.sh` et les pins (`PROJECT.md`) installent `@opengsd/gsd-core` en
  non-interactif, idempotent, avec fallback manuel ; `get-shit-done-cc` n'est plus référencé.
- [ ] **GSDM-05**: L'index factuel (`build-gsd-index.sh`) est régénéré depuis le nouveau package/binaire
  (zéro hallucination) et les références docs pointent la nouvelle source.
- [ ] **GSDM-06**: Non-régression prouvée en isolé (dry-run 3 scopes + idempotence, vrai `~/.claude` intact) ;
  CHANGELOG/README à jour ; release bumpée + tag annoté poussé (`check-release-tag.sh --remote` → ✓).

## Milestone vf-routing — Routage fin & couverture des verbes

Spec : `docs/superpowers/specs/2026-07-25-routage-fin-verbes-vf-design.md`.

### Phase 12 — Routage fin & couverture complète des verbes `/vf-*`

> ⚠️ *Post-scriptum 2026-07-26* : ces exigences décrivent l'état **livré en v2.31.0**. La façade `/vf-*`
> (verbes + rule de préséance + table de routage vers les verbes) a été **supprimée en v2.33.0**
> (bascule agentique, spec `2026-07-25-suppression-facade-vf-design.md`) : VERB-01 est inversé (carte
> d'intention unique, l'agent invoque les briques directement), les verbes de VERB-02 et l'artefact de
> VERB-04 n'existent plus sur disque, la suite de tests a été refondue (26 OK). Les cases restent
> cochées au titre de l'historique de livraison.

- [x] **VERB-01**: La table de routage de `AGENT.md` mappe chaque intention vers un **verbe `/vf-*`**
  (plus aucune cible `gsd-*` en entrée de chaîne) ; `AGENT.md` reste ≤ 250 L.
- [~] **VERB-02** *(partiel — 17/18, `vf-ingest` soldé en Phase 13)*: 18 nouveaux verbes `/vf-*` sont livrés dans `dev-orchestrator` (`vf-secure`, `vf-testgen`,
  `vf-gaps`, `vf-forensics`, `vf-inbox`, `vf-milestone`, `vf-phase`, `vf-undo`, `vf-backlog`, `vf-cleanup`,
  `vf-resume`, `vf-pause`, `vf-docs`, `vf-learn`, `vf-explore`, `vf-spike`, `vf-spec`, `vf-ingest`) + `vf-sketch`
  dans `design-orchestrator` ; chacun délègue à une cible GSD existante, aucun ne réimplémente sa logique.
- [x] **VERB-03**: Les 32 descriptions de skills (14 réécrites + 18 nouvelles) suivent le gabarit déclencheur —
  formulations FR réelles + contre-exemples nommant les verbes voisins ; les 5 groupes de collision identifiés
  sont démarqués.
- [x] **VERB-04**: Une rule de préséance globale (`rules/vf-verb-precedence.md`, ≤ 40 L, sans `paths:`) est
  livrée et installée en `.claude/rules/` : aucun skill `gsd-*` ni `superpowers:*` n'est invoqué en entrée de
  chaîne ni nommé à l'utilisateur.
- [x] **VERB-05**: `references/intent-routing.md` couvre **100 %** des skills listés dans
  `gsd-skills-index.md` (chargé on-demand) ; les tests du module passent, fixture T4 étendue aux nouvelles
  cibles + T12 (anti-collision), T13 (préséance), T14 (exhaustivité) — numérotation tranchée en
  12-CONTEXT D-03 (`T11` déjà pris par l'axe de généricité).

### Phase 13 — Pont spec → feuille de route

> Redéfinie le 2026-07-26 : la façade `/vf-*` ayant été supprimée (v2.33.0, bascule agentique), la
> capacité d'ingestion est portée par l'agent `vibeflow-dev` — pas de verbe `/vf-ingest`.

- [x] **BRDG-01**: L'agent `vibeflow-dev` intègre une spec `docs/superpowers/specs/*.md` à la feuille de
  route via `gsd-ingest-docs --mode merge` (étapes + exigences), et un plan `docs/superpowers/plans/*.md`
  via `gsd-import --from` — sans réimplémenter ni contourner les moteurs.
- [x] **BRDG-02**: La découverte des specs/plans **non encore intégrés** est outillée
  (`discover-unintegrated-docs.sh` : chemin non cité dans les 6 registres — ROADMAP, REQUIREMENTS,
  MILESTONES, PROJECT, `milestones/*.md`, `docs/ADR.md` —, détection du grain spec vs plan) ; l'agent
  construit le manifest YAML attendu par le moteur — l'utilisateur n'écrit aucun manifest à la main.
- [x] **BRDG-03**: Les garde-fous sont préservés et vérifiés : gate BLOCKER jamais contourné, confirmation
  humaine avant toute écriture dans `.planning/` (ADR-031), `--mode merge` par défaut sur projet existant,
  cap 50 documents signalé ; en fin de cadrage, l'agent propose l'ingestion comme next step.
  *Réserve (2026-07-26)* : les 4 garde-fous sont **doctrinaux** — leur présence textuelle est prouvée
  (axe T16), leur respect à l'exécution ne l'est pas et ne peut pas l'être par grep. L'audit a relevé
  que la confirmation humaine est ancrée à `vibeflow-dev` seul : `vf-dev-manager` (chemin équipe) n'a
  pas de ligne nominative sur l'ingestion, contrairement au patron appliqué aux skills de clôture de
  milestone. **Arbitrage doctrinal remonté à l'humain**, non tranché en mission.

### Phase 14 — Frontière d'altitude `planning-core` / moteur GSD

Spec : `docs/superpowers/specs/2026-07-25-rescope-vf-planning-gsd-design.md`. ADR-055.

- [x] **ALTI-01**: `scripts/detect-gsd-engine.sh` répond au **fait** « un moteur de planning GSD est-il en
  place ? » via 4 exits évalués par ordre de priorité (1 chaîne absente, 0 moteur actif, 2 migration à
  examiner, 3 terrain libre). Il **n'infère aucun métier** — les signaux de code déclenchent un examen, jamais
  un verdict ; 10 cas de test passent, dont la primauté du marqueur GSD sur les signaux de code.
- [x] **ALTI-02**: La description de `vf-planning` ne revendique plus aucune intention de projet dev
  (« feuille de route », « où en est-on ») et nomme ses voisins en contre-exemples (`/vf-init`,
  `/vf-progress`, `/vf-plan`, `/vf-map`) ; le SKILL porte une étape 0 de branchement (fait + jugement) et deux
  séquences — A (socle universel non-dev) et B (couche lab). Sur un lab dev, **aucun** artefact de projet
  (`PROJECT`, `ROADMAP`, `REQUIREMENTS`, `STATE`, `phases/`) n'est généré.
- [x] **ALTI-03**: La double injection `SessionStart` est terminée : le flag `--defer-to-gsd` (opt-in, câblé
  dans `hooks/hooks.json` uniquement) fait taire `check-planning-state.sh` et `planning-context.sh` sous
  moteur GSD. Le comportement **par défaut** de ces scripts est inchangé (usage manuel et `/checkpoint`
  intacts) et l'`INDEX.md` du lab reste injecté — c'est de l'altitude lab, GSD ne le produit pas.
- [x] **ALTI-04**: La doctrine est tracée et outillée : `references/gsd-handoff.md` (test unique, table
  intention → verbe, périmètre résiduel, protocole de migration), `domain-detection.md` amendé (le métier
  reste du jugement), commande `/vf-planning` alignée, ADR-055 au registre. `guard-planning-updated.sh` reste
  **bloquant** (exception motivée) et aucun `.planning/` existant n'est jamais réécrit (ADR-031).
- [x] **ALTI-05**: Non-régression prouvée : les 4 bundles non-dev (`content`, `business-pilot`, `growth`,
  `kpi-analyst`) passent par la séquence A sans changement, la suite de tests du module est verte,
  `check-agents.sh` OK, JSON valides ; release bumpée (module v2.4.0, racine v2.30.0) + **tag annoté poussé**
  (`scripts/check-release-tag.sh --remote` → ✓).

## v2 Requirements

### Vocabulaire & UX

- **VOC-01**: Traduction exhaustive de tous les artefacts GSD en vocabulaire VibeFlow.
- **VOC-02**: Migration automatique `get-shit-done-cc` → `@opengsd/gsd-core` quand la bascule npm est stable.
  → **Promu en milestone `gsd-migration`** (Phases 10-11, requirements GSDM-01..06).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Fork/réécriture des skills GSD | On délègue ; absorber casserait les mises à jour gratuites de GSD |
| Support multi-runtime custom (Copilot/Gemini) | Déjà géré par GSD ; hors périmètre VibeFlow |
| UI/dashboard | CLI-first, cohérent avec l'écosystème |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ROUT-01 | Phase 1 | Complete |
| ROUT-02 | Phase 1 | Complete |
| ROUT-03 | Phase 1 | Complete |
| ROUT-04 | Phase 1 | Complete |
| IDX-01 | Phase 1 | Complete |
| IDX-02 | Phase 1 | Complete |
| ABS-01 | Phase 1 | Complete |
| ABS-02 | Phase 1 | Complete |
| BOOT-01 | Phase 1 | Complete |
| BOOT-02 | Phase 1 | Complete |
| BOOT-03 | Phase 1 | Complete |
| BOOT-04 | Phase 1 | Complete |
| VERIF-01 | Phase 1 | Complete |
| VERIF-02 | Phase 1 | Complete |
| MANIF-01 | Phase 2 | Complete |
| MANIF-02 | Phase 2 | Complete |
| SCOPE-01 | Phase 3 | Complete |
| SCOPE-02 | Phase 3 | Complete |
| SCOPE-03 | Phase 3 | Complete |
| SCOPE-04 | Phase 3 | Complete |
| INST-01 | Phase 4 | Complete |
| INST-02 | Phase 4 | Complete |
| INST-03 | Phase 4 | Complete |
| INST-04 | Phase 4 | Complete |
| INST-05 | Phase 4 | Complete |
| PLUG-01 | Phase 5 | Complete |
| PLUG-02 | Phase 5 | Complete |
| PLUG-03 | Phase 5 | Complete |
| PLUG-04 | Phase 5 | Complete |
| FIRST-01 | Phase 6 | Complete |
| FIRST-02 | Phase 6 | Complete |
| PHIL-01 | Phase 7 | Complete |
| PHIL-02 | Phase 7 | Complete |
| PHIL-03 | Phase 7 | Complete |
| PHIL-04 | Phase 7 | Complete |
| PHIL-05 | Phase 7 | Complete |
| PHIL-06 | Phase 7 | Complete |
| PHIL-07 | Phase 7 | Complete |
| PHIL-08 | Phase 7 | Complete |
| CONS-01 | Phase 8 | Complete |
| CONS-02 | Phase 8 | Complete |
| CONS-03 | Phase 8 | Complete |
| CONS-04 | Phase 8 | Complete |
| RND-01 | Phase 9 | Spike done — GO (round-trip + archivage vérifiés) |
| RND-02 | Phase 9 | Done — note go/no-go + demi-vies recalibrées + cadrage swarm |
| GSDM-01 | Phase 10 | Done — inventaire 5 familles de points de contact (10-ETUDE.md §1) |
| GSDM-02 | Phase 10 | Done — cible caractérisée : successeur communautaire dominant, parité totale, chemins/bins changés (10-ETUDE.md §2) |
| GSDM-03 | Phase 10 | Note écrite et **renforcée par spike réel** (10-SOLUTIONS.md : parité SDK prouvée, 4 correctifs seulement) — GO confirmé, décision humaine en attente |
| GSDM-04 | Phase 11 | Not started (GATE Phase 10) |
| GSDM-05 | Phase 11 | Not started (GATE Phase 10) |
| GSDM-06 | Phase 11 | Not started (GATE Phase 10) |
| VERB-01 | Phase 12 | Done |
| VERB-02 | Phase 12 | Livré v2.31.0 (17/18 verbes) — **caduc depuis v2.33.0** (façade supprimée) |
| VERB-03 | Phase 12 | Done — 33 descriptions, 11 groupes à réciprocité stricte |
| VERB-04 | Phase 12 | Livré v2.31.0 (rule 40 L) — **artefact supprimé en v2.33.0** |
| VERB-05 | Phase 12 | Done — 65/65 skills routés (suite refondue v2.33.0 : 26 OK) |
| BRDG-01 | Phase 13 | Done — doctrine `ingestion-flow.md` + câblage `AGENT.md` (module v2.2.0) |
| BRDG-02 | Phase 13 | Done — `discover-unintegrated-docs.sh`, 16 cas (bornage bilatéral + ERE durcis après revue) |
| BRDG-03 | Phase 13 | Done (doctrinal) — 4 garde-fous écrits, T16 les vérifie ; portée `vf-dev-manager` en arbitrage |
| ALTI-01 | Phase 14 | Complete |
| ALTI-02 | Phase 14 | Complete |
| ALTI-03 | Phase 14 | Complete |
| ALTI-04 | Phase 14 | Complete |
| ALTI-05 | Phase 14 | Complete |

**Coverage:**
- Milestone 1 (v1) : 14 requirements — Complete ✓
- Milestone 2 (Install UX) : 17 requirements — mappés aux phases 2-6, 0 non-mappé ✓
- Milestone 3 (Doctrine dev & consolidation) : 12 requirements — mappés aux phases 7-8, 0 non-mappé ✓
- Milestone 4 (memory-swarm-rnd / R&D) : 2 requirements — mappés à la phase 9, 0 non-mappé ✓
- Milestone 5 (gsd-migration) : 6 requirements — mappés aux phases 10-11, 0 non-mappé ✓
- Milestone 6 (vf-routing) : 13 requirements — mappés aux phases 12-14, 0 non-mappé ✓
- Hors-milestone : les releases `v2.32.0 → v2.36.1` (audit croisé, bascule agentique, bundles métier,
  recettes UAT, refonte README) ont été livrées **sans requirements GSD** — tracées dans
  `MILESTONES.md` (entrée « hors-milestone ») et `docs/ADR.md` (ADR-056/057).

---
*Requirements defined: 2026-06-04*
*Last updated: 2026-07-26 — remise à l'heure post-audit (Phase 12 annotée post-bascule v2.33.0, Phase 13 redéfinie sans verbe, Phase 14 = v2.30.0, milestones 2-3 shipped) ; précédent : 2026-07-25 — ajout Phase 14 au Milestone 6 (ALTI-01→05 : frontière d'altitude planning-core / moteur GSD, ADR-055)*
