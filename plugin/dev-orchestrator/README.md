# dev-orchestrator — Orchestrateur de développement (VFDO)

> Module VibeFlow qui pilote le cycle de développement en **modèle agentique** : un agent
> `vibeflow-dev` qui détecte l'intention en langage naturel et invoque **directement** les
> briques gsd-*/superpowers installées, une **équipe de mission** (manager + workers) pour le
> multi-étapes, **2 skills** (`vf-auto`, `vf-dev`) et une **carte d'intention unique**. Plus de
> façade de verbes : GSD est l'interface directe du quotidien, l'agent est l'entrée
> conversationnelle optionnelle.

**Version** : v2.13.0
**Type** : agent + équipe d'agents + 2 skills + scripts

---

## Vue d'ensemble

Dire « aide-moi à dev », « code ça », « on est où ? » ou « débugge ce crash » déclenche le
pipeline de développement complet. Le modèle est agentique, pas une couche de synonymes :

1. **Les briques gsd-*** se déclenchent nativement sur leurs propres descriptions — c'est le
   cas courant, sans intermédiaire.
2. **L'agent `vibeflow-dev`** (`AGENT.md`) — l'entrée conversationnelle : détecte l'intention
   (y compris floue ou composite), invoque directement la brique outillée qui la porte, propose
   **LE next step** depuis la feuille de route après chaque geste fermé, déclenche l'**hygiène
   documentaire** aux bons moments (specs, STATE/ROADMAP, registres — jamais au fil de l'eau)
   et applique le **garde-fou first-use** (projet non initialisé → proposer la cartographie
   puis `gsd-new-project` sur confirmation explicite, jamais en autonomie).
3. **L'équipe de mission** (`agents/`) — pour le multi-étapes : `vf-dev-manager` planifie en
   **DAG**, tient le **lock de driver**, pilote sur **rapports typés**, embarque un **digest de
   mission** dans chaque mandat et dispatche en **parallèle** les juges indépendants
   (revue ∥ audit). Les workers (`vf-coder`, `vf-reviewer`, `vf-auditer`, en sonnet) ont chacun
   accès direct aux briques gsd de leur thème.

Le routage vit dans **UNE seule source** : `references/intent-routing.md` (carte
intention → brique, chargée on-demand par les 2 agents). Le vocabulaire GSD peut apparaître
dans les échanges — la clarté prime sur la traduction (fin de la règle de reframe).

S'y ajoutent :

- **2 skills survivants** (`skills/`) — logique réelle, pas façade :
  - `vf-auto` : porte d'autonomie — seuil `SEUIL_EQUIPE`, aiguillage `gsd-autonomous` inline
    vs équipe de mission.
  - `vf-dev` : point d'entrée générique — incarne l'agent `vibeflow-dev` (3 lignes, aucune
    table dupliquée).
- **Scripts** (`scripts/`) — bootstrap, indexation et kernel d'orchestration :
  - `ensure-deps.sh` : auto-install non-interactif et **idempotent** de GSD + Superpowers
    (fallback manuel si Node/npm ou CLI `claude` manquent — jamais d'échec silencieux).
  - `build-gsd-index.sh` : génère un **index factuel** des skills GSD installés
    (100 % auto-généré depuis le frontmatter sur disque — D4, anti-hallucination).
  - `inject-mcp-tools.sh` : injection des serveurs MCP du lab dans les agents flaggés.
  - `check-dev-bootstrap.sh` / `check-doc-drift.sh` (**nouveau**, Phase 17) : signaux de
    démarrage `SessionStart` — continuum bootstrap/onboard/orientation GSD et dérive
    documentaire, en lecture seule (voir `hooks/hooks.json` ci-dessous).
  - Le kernel d'orchestration de mission (`dag.sh` / `driver-lock.sh`, ADR-053) est **consommé
    depuis le team-kernel hébergé par `conductor`** depuis la v2.34.0 (d'où `requires` →
    `conductor`) — il ne vit plus dans ce module.
- **`hooks/hooks.json`** (**nouveau**, Phase 17) : premier fragment de hooks du module —
  `SessionStart:startup` déclenche `check-dev-bootstrap.sh`, `discover-unintegrated-docs.sh` et
  `check-doc-drift.sh` en mode `--hook`, chacun suffixé `|| true` (advisory, ADR-031, jamais
  bloquant). Ce fragment ne couvre que les hooks VibeFlow : les hooks `gsd-*` posés par
  `gsd-core` lui-même (ex. `gsd-ensure-canonical-path.js`, `gsd-update-banner.js`) restent hors
  de son périmètre — arbitrage écrit, pas un oubli (ADR-062).

---

## Structure du module

```
dev-orchestrator/
├── AGENT.md                       # agent vibeflow-dev (≤250L, dense)
├── agents/                        # équipe de mission
│   ├── vf-dev-manager.md          # manager de mission — exposé (opus)
│   ├── vf-coder.md                # worker interne (vf-internal: true, sonnet)
│   ├── vf-reviewer.md             # worker interne (vf-internal: true, sonnet)
│   └── vf-auditer.md              # worker interne (vf-internal: true, sonnet)
├── hooks/
│   └── hooks.json                 # SessionStart : signaux de démarrage (Phase 17)
├── skills/
│   ├── vf-auto/SKILL.md           # porte d'autonomie (seuil équipe)
│   └── vf-dev/SKILL.md            # point d'entrée générique (incarne l'agent)
├── scripts/
│   ├── ensure-deps.sh             # bootstrap deps (idempotent, dry-run testable)
│   ├── build-gsd-index.sh         # index factuel (VF_INDEX_OUT surchargeable)
│   ├── inject-mcp-tools.sh        # injection MCP dans les agents flaggés
│   ├── discover-unintegrated-docs.sh # découverte doctrine ingestion (+ mode --hook)
│   ├── check-dev-bootstrap.sh     # signal bootstrap/onboard/orientation GSD (Phase 17)
│   ├── check-doc-drift.sh         # signal dérive documentaire (Phase 17)
│   └── tests/                     # suites de vérification
│       ├── test-check-dev-bootstrap.sh
│       └── test-check-doc-drift.sh
└── references/                    # doctrine + index chargés on-demand par les agents
    ├── intent-routing.md           # carte intention → brique (SEULE source de routage)
    ├── GSD-PIPELINE.md             # ordre canonique du cycle + model profiles
    ├── gsd-skills-index.md         # auto-généré (NE PAS ÉDITER)
    ├── mission-contracts.md        # Brief / Digest / Rapport de mission + SEUIL_EQUIPE
    ├── mission-flow.md             # lock + DAG + rapports typés (ADR-053)
    ├── ingestion-flow.md           # ingestion BRDG-01/03, chargée on-demand
    ├── docs-flow.md                # sortie doc DOCF-01/04, chargée on-demand (Phase 22)
    └── autonomous-guardrails.md    # garde-fous des boucles autonomes
```

> **`intent-routing.md` vs `gsd-skills-index.md`** — l'index est un **inventaire factuel**
> auto-généré (« ce skill est-il installé ici ? ») et ne s'édite jamais ; `intent-routing.md`
> est la **doctrine** écrite à la main (« quelle intention mène à quelle brique ? »). Quand
> l'index évolue, c'est la doctrine qui s'aligne sur lui — jamais l'inverse.

---

## Installation (via vibeflow-update.sh)

```bash
# depuis votre lab
.claude/scripts/vibeflow-update.sh install dev-orchestrator
```

L'installeur pose, de bout en bout :

- l'agent → `.claude/agents/dev-orchestrator.md`
- l'équipe de mission → `.claude/agents/` (manager + 3 workers)
- les 2 skills → `.claude/skills/vf-auto/`, `.claude/skills/vf-dev/`
- les scripts → `.claude/scripts/` (+ tests)
- les références (**D7**) → `.claude/agents/dev-orchestrator-references/`
  (`intent-routing.md`, `GSD-PIPELINE.md`, `gsd-skills-index.md`, `mission-contracts.md`,
  `mission-flow.md`, `autonomous-guardrails.md`)
- un **index frais** : à l'install, `build-gsd-index.sh` est ré-exécuté avec
  `VF_INDEX_OUT=.claude/agents/dev-orchestrator-references/gsd-skills-index.md` (IDX-02).
  Best-effort : si GSD est absent, l'install n'échoue pas — l'index sera régénéré plus tard.

> **Note D7** — les références d'un module agent sont installées sous
> `.claude/agents/<mod>-references/`, pas sous `.claude/skills/`. L'agent les charge
> on-demand (densité préservée : l'`AGENT.md` n'embarque que les raccourcis dominants).

---

## Usage

### Langage naturel (recommandé)

L'utilisateur parle normalement ; les briques gsd-* se déclenchent nativement, ou l'agent
`vibeflow-dev` détecte l'intention et invoque la brique :

| Vous dites… | Brique invoquée (coulisse) |
|---|---|
| « démarre un projet » (confirmation explicite) | `gsd-new-project` (après le garde-fou first-use) |
| « cartographie le code », « c'est quoi ce repo ? » | `gsd-map-codebase` |
| « réfléchis à… », « et si on… » | superpowers `brainstorming` / `gsd-explore` |
| « planifie », « cadre cette feature » | `gsd-discuss-phase` puis `gsd-plan-phase` |
| « code ça », « implémente la feature X » | `gsd-execute-phase` (trivial : `gsd-quick`) |
| « teste », « ça marche ? » | `gsd-verify-work` |
| « relis », « regarde ce diff » | `gsd-code-review` |
| « ça plante », « débugge » | `gsd-debug` (recherche doc d'abord — ADR-045) |
| « fais tout en autonomie » | skill `vf-auto` |
| « livre », « crée une PR » | `gsd-ship` |
| « on est où ? », « la suite » | `gsd-progress` + next step proposé |

La carte exhaustive (~65 gestes, familles amont/construction/qualité/cycle de
vie/contexte/design/mission) : `references/intent-routing.md`.

Le module `design-orchestrator`, installé d'office avec celui-ci, porte l'intention design
(`/vf-design`, `vf-sketch`). Deux intentions voisines appartiennent à d'autres modules et ne
sont **jamais** captées ici : `/vf-audit` (conformité du lab, module `validator`) et
`/vf-planning` (socle de planning du lab, module `planning-core`, ADR-055).

### Parcours types

- **Premier contact (dossier vierge)** : le garde-fou first-use détecte l'absence de
  `.planning/` → propose la cartographie puis `gsd-new-project` (sur confirmation, BOOT-04).
- **Projet existant** : `gsd-map-codebase` → `gsd-discuss-phase`/`gsd-plan-phase` →
  `gsd-execute-phase` → `gsd-verify-work`.
- **Tâche unique rapide** : `gsd-quick` (ou dites simplement « corrige ce typo »).
- **En autonomie totale** : `vf-auto` enchaîne cadrage → plan → exécution tout seul, avec les
  garde-fous de boucle (`references/autonomous-guardrails.md`).

### Équipe de mission

Pour les missions multi-étapes (« les étapes 3 à 5 », « toute la milestone », « la nuit »),
l'agent **propose** de déléguer à `vf-dev-manager` : la conversation principale reste légère,
le manager planifie (DAG) / décide (panels) / distribue (digest de mission ≤ 30 lignes par
mandat) et pilote sur rapports typés — juges indépendants dispatchés en parallèle
(revue ∥ audit), fusion des findings, un seul reopen. `vf-auto` bascule automatiquement vers
l'équipe au-delà de `SEUIL_EQUIPE` étapes restantes ou sur signal de durée. Contrats et seuil :
`references/mission-contracts.md` ; discipline de pilotage : `references/mission-flow.md`
(ADR-053).

### Bootstrap des dépendances

Au premier contact, l'agent lance `ensure-deps.sh` : auto-install non-interactif de
GSD + Superpowers, idempotent. `gsd-new-project` n'est **jamais** lancé seul — uniquement
proposé sur confirmation explicite (BOOT-04).

---

## Tests

```bash
bash dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
```

Couvre les axes de la bascule agentique (spec 2026-07-25) plus les acquis :

- **T1** — index factuel non vide (SKIP si GSD absent) · **T2/T2b** — `ensure-deps.sh`
  idempotent + scopé (dry-run, sans réseau).
- **T3** — `AGENT.md` : table d'intentions fournie (≥11 lignes) et **aucune référence à un
  verbe supprimé** (la façade des 29 verbes est morte, elle ne doit pas ressusciter).
- **T4** — aucune cible orpheline dans les skills (index disque ou fixture canonique — la
  fixture garde la suite verte **aussi sans chaîne interne installée**, CI comprise).
- **T5** — densité par `wc -l` : `AGENT.md` ≤250L, skills ≤500L.
- **T6** — install end-to-end via `vibeflow-update.sh` (best-effort, SKIP sinon).
- **T7** — garde-fou first-use présent dans `AGENT.md` (FIRST-01/FIRST-02, BOOT-04).
- **T8/T8b/T8c** — équipe de mission : 4 agents conformes (frontmatter, densité,
  `vf-internal` sur les workers — Pattern 12) + `check-agents.sh --strict` (ADR-044).
- **T9** — contrats de mission : source unique `mission-contracts.md` (Brief + **Digest** +
  Rapport + SEUIL_EQUIPE) + renvois DRY (router, vf-auto, manager).
- **T10** — routage mission (`AGENT.md` → vf-dev-manager) + aiguillage taille (`vf-auto`).
- **T11** — généricité : aucun renvoi vers un chemin absent d'un lab installé (DM5).
- **T12** — les 2 skills survivants ont une description valide et sans verbe supprimé.
- **T13** — la façade est bien morte : les artefacts du reframe (carte de vocabulaire) et de
  la préséance (rule globale) n'existent plus, aucun skill fantôme au-delà des 2 survivants,
  aucun verbe supprimé référencé dans les fichiers du module.
- **T14** — exhaustivité : chaque skill de l'index factuel est routé par `intent-routing.md`
  (SKIP si l'index est vide, c'est-à-dire sans chaîne installée).
- **T15** — pipelining N/N+1 : `mission-flow.md` modélise le DAG fin (discuss/plan/execute par
  étape, règle de provisoire), `vf-dev-manager.md` y renvoie avec la consigne compacte.
- **T16** — doctrine d'ingestion (BRDG-01/BRDG-03) : `ingestion-flow.md` porte le script, ses
  3 exits, le schéma manifest et les 4 garde-fous ; `AGENT.md` y renvoie en Références.
- **T17** — câblage du routage d'ingestion : `AGENT.md` porte une ligne d'intention explicite,
  `intent-routing.md` conserve sa ligne enrichie du renvoi vers `ingestion-flow.md`.
- **T18/T18b** — cloisonnement par tools (Pattern 12) du **manager** : allowlist `Agent(...)`
  complète (18 noms testés un par un), `vf-design-manager` absent (imbrication manager→manager
  interdite), parenthèse fermée ; doctrine d'étage design présente et routage `vf-auto` vers un
  mandat entièrement design.
- **T19 → T19f** — miroir de T18 côté **workers** (ferme le chemin indirect
  manager→worker→manager, Phase 16) : allowlist `Agent(...)` de `vf-coder`/`vf-reviewer`/
  `vf-auditer` vérifiée **nom par nom** par extraction bornée à la profondeur de parenthèses
  (jamais un grep sur la ligne entière — non tautologique), aucun manager dans aucune des trois
  listes, aucun `Agent` nu, parenthèses correctement refermées, `general-purpose` nommément
  présent chez `vf-coder` (cadrage non-interactif de `discuss-phase`), garde anti-homonyme (un nom
  préfixe littéral d'un autre — ex. `gsd-planner`/`gsd-plan-checker` — ne le valide jamais).
- **T20** — gate ADR-044 réellement falsifiable sur `AGENT.md` (Phase 17) : `check-agents.sh
  --file` (jamais à nu — `AGENT.md` est hors de la boucle CI `plugin/*/agents`), triple
  assertion (exit 0, compte de warnings == baseline 3, présence des 3 types connus).
- **T21** — invariants SC5 par grep structurel (Phase 17) sur `check-dev-bootstrap.sh` et
  `check-doc-drift.sh` : aucun `exit 1`, aucune écriture hors `/dev/null`/descripteur/variable
  `*TMP*`, aucune commande d'écriture directe, tout `mktemp` apparié à un `trap ... EXIT`.
- **T22** — doctrine `docs-flow.md` (Phase 22) : les quatre familles documentaires, les trois
  régimes de confirmation (`--verify-only` libre, génération sous confirmation, `--force` sous
  garde-fou en trois temps sur une même ligne rouge), le renvoi vers `ingestion-flow.md` pour la
  famille entrée (jamais une copie), et la captation d'intention (`AGENT.md` +
  `intent-routing.md`) qui route les trois régimes séparément.
- **T23** — câblage du geste documentaire dans les deux managers de mission (`vf-dev-manager` et
  `vf-design-manager`, `dev-orchestrator` + `design-orchestrator`) : nœud `docs` agrégé posé en
  fin de mission par chacun, quatre déclencheurs testés un par un, `SKIP` si le module design est
  hors du périmètre scanné.

Exit 0 si tout passe (les SKIP, ex. GSD absent, ne font pas échouer la suite).

---

## Références

- Doctrine d'ingestion (découverte, manifest, garde-fous BRDG-03) : `references/ingestion-flow.md`
- Doctrine de sortie documentaire (4 familles, 3 régimes, ligne rouge `--force`) : `references/docs-flow.md`
- Spec de la bascule agentique : `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`
- Spec d'origine du module : `docs/superpowers/specs/2026-06-04-dev-orchestrator-design.md`
- Équipe de mission : `docs/superpowers/specs/2026-07-09-dev-manager-team-design.md` (DM1-DM6)
- ADR-053 : discipline de pilotage swarm (lock + DAG + rapports typés)
- ADR-045 : recherche documentaire avant debug empirique
- D3 : auto-install des deps, init sur confirmation seulement
- D4 : index 100 % auto-généré (anti-hallucination)
- D7 : références d'un module agent sous `.claude/agents/<mod>-references/`
- IDX-02 : index régénéré à l'install via `VF_INDEX_OUT`

## Historique

- **v2.6.0** — signaux de démarrage du moteur de dev (Phase 17) : premier fragment
  `hooks/hooks.json` du module (`SessionStart:startup`), `check-dev-bootstrap.sh` (continuum à
  4 états bootstrap/onboard/orientation GSD) et `check-doc-drift.sh` (dérive documentaire,
  seuil réglable) nouveaux, `discover-unintegrated-docs.sh --hook` (extension additive, contrat
  historique inchangé), section `AGENT.md` « Signaux de démarrage », gates T20/T21 (suite portée
  à 60 axes). Portabilité prouvée en conteneur Linux avant push.
- **v2.5.0** — allowlists `Agent(...)` posées sur les 3 workers internes (Phase 16) :
  `vf-coder` (22 noms), `vf-reviewer` (1), `vf-auditer` (1), fermant le chemin indirect
  manager→worker→manager ; aucun manager dans aucune des trois listes.
- **v2.4.0** — étages croisés dev ↔ design (Phase 15) : `vf-dev-manager` dispatche `vf-crafter`
  (`craft:<écran>`) avant une étape UI et `vf-design-judge` (`critique:<écran>`) en parallèle de
  la revue code, sans jamais dispatcher `vf-design-manager` ; brief enrichi
  (`design: auto|force|off`, `livrable: specs|specs+implementation`) ; allowlist `Agent(...)`
  portée à 18 noms.
- **v2.2.1** — échappatoire ADR-031 fermée : l'ingestion remonte nominativement à l'humain
  depuis `vf-dev-manager` aussi (jamais déclenchée en mission sans confirmation).
- **v2.2.0** — câblage de l'ingestion (BRDG-01/BRDG-03) dans `vibeflow-dev` : doctrine
  `references/ingestion-flow.md` (découverte, manifest, délégation `gsd-ingest-docs`/
  `gsd-import`, garde-fous BLOCKER/ADR-031/mode merge/cap 50), proposée comme next step en fin
  de cadrage.
- **v2.1.1** — recette dev en lab sandbox : cascade `$S` (le lab courant prime sur le scope
  user), doctrine `human_needed` en autonome, `requires` += `conductor` (team-kernel).
- **v2.1.0** — pipelining N/N+1 : cadrage+plan de l'étape suivante pendant l'exécution de la
  courante ; `dag.sh`/`driver-lock.sh` consommés depuis le team-kernel du `conductor`.
- **v2.0.0** — bascule agentique : suppression des 29 verbes-façades, fin du reframe et de la
  préséance, carte d'intention unique, manager upgradé (intention / next steps / hygiène doc /
  digest de mission).
- **v1.8.x** — routage fin : 31 verbes, rule de préséance, doctrine exhaustive (remplacé par
  la v2).
- **v1.5.0** — équipe manager de mission (manager + workers cloisonnés).
- **v1.0.0** — routeur initial (agent + verbes + index factuel).
