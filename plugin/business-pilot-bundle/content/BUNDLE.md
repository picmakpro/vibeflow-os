# MANIFESTE — Bundle métier `business-pilot`

> **⚑ Matérialisé le 2026-07-25** — ce document reste la **trace de conception** du bundle ;
> le réel vit désormais dans `agents/` (équipe installable sur le team-kernel :
> `vf-business-manager` + `vf-business-commercial` / `vf-business-delivery` /
> `vf-business-finance` + `quality-gate-client`) et `skills/vf-business/` (point d'entrée
> métier). Les blueprints ci-dessous ne sont plus la voie d'instanciation primaire :
> `vf-new-lab` installe le module et n'instancie plus à la main. Le gate qualité « à
> fabriquer » (§8) est désormais LIVRÉ comme agent juge read-only.

> Fichier **source de dérivation** lu par `vf-new-lab` (module `conductor`) pour instancier un lab de
> pilotage de business. Il déclare le métier, le profil de planning, l'extension de domaine, le
> vocabulaire natif, les agents à poser, les modules requis et le **flux d'instanciation**.
>
> **Doctrine** : ce bundle **transpose** (P7) la doctrine VibeFlow dans le vocabulaire d'un opérateur
> de business — il ne plaque aucune forme dev. Les principes Core P1–P9 sont **référencés, jamais
> redupliqués** (canon : module `reference`, `VIBEFLOW_CORE.md`).

---

## 1. Métier piloté

**business-pilot** — piloter un business généraliste de bout en bout :

**Offre → Pipeline commercial → Delivery → Revenus**, sous gouvernance VibeFlow (tracé, capitalisé,
audité). Cible : agence, freelance structuré, studio, cabinet, petit éditeur de service.

## 2. Profil de rigueur planning

**`standard`** (mapping métier → profil : `planning-core/references/PROFILES.md`).

Implication concrète dans `.planning/` :
- Tronc invariant : `STATE.md` (clé de voûte), `PROJECT.md`, `ROADMAP.md`, `config.json`.
- Profil ≥ standard : `REQUIREMENTS.md`, `MILESTONES.md` + `milestones/`, arbo `phases/NN/`.
- Extension de domaine métier : **`business/`** (voir §5 et `content/domain/extension-spec.md`).

> `config.json` porte `"profile": "standard"`. Le profil n'est jamais imposé : `vf-new-lab` le
> **propose pré-coché** et l'utilisateur peut le rétrograder en `léger`.

## 3. Extension de domaine

**Nom : `business/`** (sous `.planning/`). **PAS** `codebase/` — le métier n'est pas le code.

Spécification exacte (dossiers, fichiers, rôles) : **`content/domain/extension-spec.md`**.
Fichier **index lu en premier** par l'agent commercial : `.planning/business/PIPELINE.md`.

## 4. Vocabulaire métier (transposition P7)

Le lab parle le langage de l'opérateur, pas le jargon dev :

| Terme natif | Définition opérationnelle | Équivalent générique |
|---|---|---|
| **Sprint stratégique** | Cycle court de pilotage du business (revue + décisions + cap). | itération / sprint |
| **Initiative** | Chantier métier à valeur (lancer une offre, ouvrir un canal, fiabiliser le delivery). | epic / chantier |
| **Obstacle** | Ce qui bloque l'avancée d'une initiative et exige un arbitrage. | blocker |
| **Rollout** | Mise en service d'une décision métier (nouvelle offre, nouveau pricing, nouveau process). | déploiement / release |

> Ce vocabulaire est injecté dans `CLAUDE.md`, `ROADMAP.md` et les sorties d'agents. Les **IDs des
> registres mémoire restent canon** (DEC/LRN/BLK/EVAL) — on transpose le vocabulaire métier, pas la
> convention de mémoire (voir `content/registres.md`).

## 5. Les 3 agents métier

Chacun s'instancie en agent natif **≤ 250 lignes** (ADR-029) ; le savoir est **déporté en `skills:`**
(jamais inliné). Spécification complète : `content/agents/<agent>.blueprint.md`.

| Agent | Rôle (1 ligne) | Modèle |
|---|---|---|
| **business-pilot-commercial** | Pilote le pipeline commercial de la qualification au closing (qualif/scoring, propositions, pricing préparé). | sonnet |
| **business-pilot-delivery** | Exécute et suit les prestations (onboarding, jalons, SLA, satisfaction, détection d'upsell). | sonnet |
| **business-pilot-finance** | Pilote revenus, facturation préparée, rentabilité et prévisions ; trace les EVAL sur les décisions quantitatives (P8). | sonnet |

**Frontière non négociable entre agents** :
- Le **commercial** ne facture jamais → transmet au **finance**.
- Le **delivery** ne négocie/ne code jamais → escalade upsell au **commercial**.
- Le **finance** ne négocie jamais → alerte, n'engage pas.
- **Aucun** des trois n'orchestre : ils **produisent** dans leur domaine. Comme le lab a ≥2 spécialistes,
  `vf-new-lab` pose **en plus un orchestrateur métier** (`business-pilot`, skill `metier-orchestration`,
  ADR-048) qui planifie/délègue/fait vérifier/réconcilie/met à jour le planning — **sans jamais produire**
  (P3). Le `conductor` reste **méta** (config/audit/migration + escalades C4), il ne fait pas ce travail métier.

## 6. Modules recommandés

| Module | Pourquoi |
|---|---|
| `planning-core` | Socle `.planning/` + extension `business/` (profil standard). |
| `consolidator` | Tenir la mémoire propre (index/archive/fusion/promotion D-NN → DEC). |
| `audit-architecture` | **Filet P8** : verdict bloquant sur les générateurs brief→output (pricing, propositions, prévisions). |
| `validator` | Agent `vibeflow-validator` — audit de cohérence lab ↔ doctrine. |
| `conductor` | **Méta** : config/audit/migration + réception des escalades C4 (déjà présent : c'est lui qui exécute `vf-new-lab`). **PAS** l'orchestration métier quotidienne. |
| orchestrateur métier `business-pilot` | **Orchestration métier** (posé d'office car ≥2 spécialistes, ADR-048) : pilote les missions, délègue aux 3 agents, fait vérifier, met à jour `.planning/`. |

> **PAS** `dev-orchestrator` (le métier n'est pas le code). **Ne pas créer** d'agent strategist ni
> d'agent auditor séparés : l'arbitrage métier est à l'**orchestrateur métier** (`business-pilot`),
> l'arbitrage de **structure** au `conductor`, l'audit au `validator` + `audit-architecture`.

## 7. Châssis doctrine ré-embarqué (référencé, non dupliqué)

- **P1 Capitaliser** — chaque agent capitalise dans les registres (voir `content/registres.md`).
- **P3 Orchestrer** — orchestration au conductor ; les agents métier ne s'auto-coordonnent pas.
- **P4 Clarifier avant d'exécuter** — un agent qui manque un input le demande, il ne devine pas.
- **P5 Vérifier en boucle** — gate de vérif avant tout livrable client (rule path-scopée, voir §8).
- **P7 Transposer, pas copier** — vocabulaire métier natif (§4), registres restent canon.
- **P8 Évaluer** — EVAL systématique sur pricing/prévisions (finance), audit bloquant via `audit-architecture`.
- **P9 Modulariser** — chaque agent ≤ 250L, savoir en skills, une responsabilité par agent.

## 8. Garde-fous spécifiques métier

- **LRN-068 enforced** — le Lab **prépare et documente** ; l'**exécution réelle** (envoi de facture,
  signature de contrat, encaissement) reste **dans les outils** via MCP (compta, CRM, paiement). Le
  Lab ne se prétend jamais le système d'enregistrement.
- **Gate qualité avant envoi client** — une rule path-scopée (`.planning/business/pipeline/delivery/**`
  et propositions) impose la vérification (P5) avant tout livrable sortant. À matérialiser à l'install.
- **EVALS systématique** — toute décision **quantitative** (pricing, prévision de revenus, seuil de
  marge) trace un `EVAL-XXX` avec ré-évaluation J+30/J+60/J+90 (P8).
- **Convention registres canon** — **pas de BDR custom** : DECISIONS/LEARNINGS/BLOCKERS/JOURNAL/EVALS.

---

## 9. Flux d'instanciation (consommé par `vf-new-lab`)

> Étapes que `vf-new-lab` exécute en lisant ce manifeste. Chaque étape **délègue** au module outillé ;
> `vf-new-lab` ne réinvente rien.

1. **Confirmer le métier** — capter/confirmer `business-pilot` (offre + pipeline + delivery + revenus)
   en une passe ; ne re-questionner que ce qui n'est pas dérivable de ce manifeste.

2. **Poser `CLAUDE.md` du lab** — constitution métier (WHY/WHAT/HOW) **en vocabulaire §4** (Sprint
   stratégique / Initiative / Obstacle / Rollout). Référencer P1–P9 vers le module `reference`, ne
   pas les recopier.

3. **Instancier les 3 agents** — pour chaque `content/agents/*.blueprint.md`, créer un agent natif
   dans `.claude/agents/` du lab :
   - frontmatter cible du blueprint (`name`, `description`, `model`, `memory: project`, `skills: [...]`) — sans `description` l'agent n'est JAMAIS auto-routé ; conformité vérifiée par `check-agents.sh` (ADR-044) ;
   - corps **≤ 250 lignes** (ADR-029) — savoir déporté en skills, jamais inliné ;
   - les **skills déclarés** sont créés **via `skill-creator`** s'ils n'existent pas (ne pas inventer
     un nom de skill sans le matérialiser).

4. **Scaffolder le socle planning** — déléguer à `vf-planning` (planning-core) :
   profil **`standard`** + extension de domaine **`business/`** selon `content/domain/extension-spec.md`.
   `STATE.md` est créé en priorité (clé de voûte).

5. **Poser les 5 registres mémoire** — DECISIONS / LEARNINGS / BLOCKERS / JOURNAL / EVALS, chacun
   ouvert par un **index tableau** (depuis `reference`/`consolidator`), conventions d'IDs de
   `content/registres.md`. Établir le **pont planning↔mémoire** (D-NN de `PROJECT.md` → DEC ;
   `STATE.md` → JOURNAL) — **un seul propriétaire par information, jamais de doublon**.

6. **Câbler le filet d'audit** — instancier l'agent **`vibeflow-validator`** (module `validator`) et
   rendre disponible le skill **`audit-architecture`** ; matérialiser la **rule de gate qualité**
   (§8). « **Pas de lab sans filet.** »

7. **Câbler l'orchestration** — déclarer que l'orchestration et les escalades passent par le
   **conductor** (contrat C4 : tout agent escalade un signal hors périmètre au conductor). Les agents
   métier ne s'orchestrent pas entre eux.

8. **Stamper la version framework** — `framework-version.sh stamp` (module conductor) pour permettre
   la détection d'update ultérieure.

9. **Récap** — montrer l'arbo `.planning/business/` posée, les 3 agents créés, les registres, le
   filet câblé, et **la première action métier** en vocabulaire du lab
   (ex. « ouvre ton premier Sprint stratégique : qualifie le pipeline »).

> **Critère de lab “fini”** : `.planning/` + extension `business/` + 3 agents ≤250L + 5 registres
> indexés + `vibeflow-validator` + `audit-architecture` câblés + orchestration déléguée au conductor
> + version stampée. Si un seul de ces éléments manque → le lab n'est pas livrable.
