# business-pilot-bundle

> Module **doc-only** du plugin **vibeflow-os**. Un *bundle métier* : il ne s'installe pas comme un
> agent unique, il porte des **blueprints** que `vf-new-lab` lit et **instancie** en un lab métier
> complet, gouverné, avec son filet d'audit.

---

## Ce qu'est ce bundle

`business-pilot-bundle` est un **paquet de doctrine métier** pour piloter un **business généraliste**
sous gouvernance VibeFlow : offres, pipeline commercial, delivery des prestations, revenus.

Il fournit, sous forme de **documentation instanciable** (jamais de code applicatif) :

- un **manifeste** (`content/BUNDLE.md`) qui décrit le métier, le profil de planning, l'extension de
  domaine et le **flux d'instanciation** ;
- **3 blueprints d'agents métier** prêts à instancier (`content/agents/`), chacun conçu pour tenir en
  **≤ 250 lignes** une fois posé (charte densité ADR-029) ;
- la **spécification de l'extension de domaine** `business/` à scaffolder (`content/domain/`) ;
- la **spécification des 5 registres mémoire canon** et du pont planning↔mémoire (`content/registres.md`).

## Pour quel métier

Pour un **opérateur de business** (agence, freelance structuré, studio, cabinet, petit éditeur de
service) qui veut un poste de pilotage IA gouverné couvrant la chaîne :

**Offre → Pipeline commercial → Delivery → Revenus**, le tout tracé et capitalisé.

Vocabulaire natif du lab (P7 — transposer, pas copier) :

| Terme métier | Sens |
|---|---|
| **Sprint stratégique** | Cycle court de pilotage (équiv. d'une itération de roadmap métier). |
| **Initiative** | Chantier métier à valeur (lancer une offre, ouvrir un canal, fiabiliser le delivery). |
| **Obstacle** | Ce qui bloque l'avancée d'une initiative (équiv. métier d'un blocker). |
| **Rollout** | Mise en production d'une décision métier (nouvelle offre, nouveau pricing, nouveau process). |

## Comment `vf-new-lab` l'utilise

Quand l'utilisateur demande « monte-moi un lab pour piloter mon business », le skill `vf-new-lab`
(module `conductor`) :

1. **Détecte** que le métier correspond à `business-pilot` (ou l'utilisateur le désigne).
2. **Lit `content/BUNDLE.md`** de ce bundle comme source de dérivation (au lieu de tout réinventer).
3. **Instancie** chaque blueprint de `content/agents/` en un agent natif Claude Code dans
   `.claude/agents/` du lab cible (≤ 250 lignes, savoir déporté en `skills:`).
4. **Scaffolde** l'extension de domaine `business/` selon `content/domain/extension-spec.md`, via
   `planning-core` (profil `standard`).
5. **Pose** les 5 registres mémoire canon selon `content/registres.md`.
6. **Câble le filet** : agent `vibeflow-validator` + skill `audit-architecture`.
7. **Stampe** la version du framework dans le lab.

> Détail pas-à-pas du flux : section *Flux d'instanciation* de `content/BUNDLE.md`.

## Contenu du module

```
business-pilot-bundle/
├── module.json                 # déclaration (doc-only, requires planning-core/consolidator/audit-architecture/validator)
├── VERSION                     # v1.0.0
├── CHANGELOG.md
├── README.md                   # ce fichier
└── content/
    ├── BUNDLE.md               # MANIFESTE + flux d'instanciation (lu par vf-new-lab)
    ├── agents/
    │   ├── business-pilot-commercial.blueprint.md
    │   ├── business-pilot-delivery.blueprint.md
    │   └── business-pilot-finance.blueprint.md
    ├── domain/
    │   └── extension-spec.md   # structure exacte de l'extension business/
    └── registres.md            # 5 registres canon + IDs + pont planning↔mémoire
```

## Dépendances

| Module | Rôle dans le lab instancié |
|---|---|
| `planning-core` | Socle `.planning/` (STATE/PROJECT/ROADMAP/config) + extension de domaine `business/`. |
| `consolidator` | Indexation/archivage/fusion/promotion des registres mémoire. |
| `audit-architecture` | Filet P8 : verdict bloquant sur les générateurs brief→output (pricing, propositions, prévisions). |
| `validator` | Agent `vibeflow-validator` — audit de cohérence lab ↔ méthodologie. |

L'**orchestration** est assurée par le module **`conductor`** (vibeflow-conductor) : ce bundle **ne
re-code pas d'orchestrateur** et les agents métier **ne font pas l'orchestration** — ils escaladent
au conductor.

## Ce que ce bundle n'est PAS

- ❌ Un agent installable directement (l'installeur ne gère qu'1 `AGENT.md`/module ; ici les agents
  sont des **blueprints** instanciés par `vf-new-lab`).
- ❌ Du code applicatif (aucune hypothèse « dev », pas de `codebase/`).
- ❌ Un orchestrateur (rôle du `conductor`) ni un auditeur (rôle de `validator` + `audit-architecture`).
