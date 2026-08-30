# reference — Documentation Méthodologique VibeFlow

> **Module doc-only** : référence canonique de la méthodologie VibeFlow.
> 77 fichiers (612 KB) — méthodologie + 12 patterns + 5 skills + 42 fichiers de templates + 1 exemple complet.

**Version** : v2.5.4 (alignement VibeFlow Core v4.2 — 9 principes P1-P9)
**Source** : le contenu canonique vit dans `plugin/reference/content/` ; l'installation le copie en `docs/reference/` dans le lab cible.

---

## Quoi

Documentation complète de la méthodologie VibeFlow, distribuable et utilisable comme référence dans n'importe quel lab. Contient :

```
content/
├── README-CLIENT.md                       # Présentation pour utilisateur final
├── VERSION.md                              # Détail de la version distribuée
├── LICENSE.md                              # Licence d'usage personnel
├── methodology/
│   ├── VIBEFLOW_CORE.md                    # Bible méthodologique v4.2 (9 principes P1-P9)
│   ├── VIBEFLOW_PHILOSOPHY.md              # Philosophie
│   ├── VIBEFLOW_EXPLAINED.md               # Vulgarisation avec analogies
│   ├── AXIOMES-ENFORCEMENT.md              # 3 axiomes transverses (enforcement>prose, filet fonctionnel, preuve avant done)
│   ├── patterns/                           # 12 patterns architecturaux universels
│   │   ├── 01-constitution.md
│   │   ├── 02-registres.md
│   │   ├── 03-agents.md
│   │   ├── 04-skills.md
│   │   ├── 05-regles.md
│   │   ├── 06-capitalisation.md
│   │   ├── 07-transposition.md
│   │   ├── 08-evaluer.md
│   │   ├── 09-meta-procedures.md
│   │   ├── 10-plan-review-adversarial.md
│   │   ├── 11-halt-conditions.md
│   │   └── 12-cloisonnement-outils.md
│   ├── vocabulary/                         # Lexique + forks-mapping + dire/ne-pas-dire
│   └── templates/                          # 42 fichiers de templates génériques
│       ├── memory/ (7)
│       ├── agents/ (9 + _reference)
│       ├── triggers/ (5)
│       ├── rules/ (1)
│       ├── docs/ (5)
│       └── skills/ (5 : agent-density-auditor, debugger, metier-orchestration, safe-execute, skill-creator)
└── examples/
    └── PetitsCoursFlow/                    # Exemple fictif complet (Sophie K., professeure de musique)
```

---

## Installation

```bash
.claude/scripts/vibeflow-update.sh install reference
```

**Installation = copie de `content/` vers `docs/reference/`** du lab cible (mode doc-only).

Aucun fichier dans `.claude/` n'est installé — c'est de la documentation, pas du runtime.

**Pré-requis** : `vibeflow-update.sh` v1.3.0+ (support modules doc-only).

---

## Usage

### Lecture méthodologie

```bash
# Ouvrir la bible méthodologique
cat docs/reference/methodology/VIBEFLOW_CORE.md

# Consulter un pattern spécifique
cat docs/reference/methodology/patterns/02-registres.md
cat docs/reference/methodology/patterns/06-capitalisation.md
```

### Onboarding équipe

Le `README-CLIENT.md` est pensé pour un onboarding nouveau membre. Pointer vers `docs/reference/README-CLIENT.md`.

### Référence templates

Quand on crée un nouvel agent / skill / registre, consulter le template correspondant dans `docs/reference/methodology/templates/`.

### Exemple PetitsCoursFlow

Lab fictif complet (Sophie K., professeure de musique) qui démontre tous les patterns en contexte. Utile comme modèle pour bootstrap un nouveau Lab.

---

## Historique des versions

Résumé du `CHANGELOG.md` du module :

- **v2.0.0** (2026-05-24) — Release initiale dans vibeflow-os : Core v4.1 (8 principes), 11 patterns, 4 skills, exemple PetitsCoursFlow.
- **v2.1.x** (2026-05/06) — Core v4.1 → **v4.2** : ajout du principe **P9 — Modulariser pour la cognition** (9 principes) + pointeur P8 vers `audit-architecture` (ADR-036).
- **v2.2.x** (2026-07) — Canon DECISIONS.md/DEC-XXX (`adr-template` → `decisions-template`, ADR-043) + `memory: project` sur les 7 templates agents (ADR-044).
- **v2.3.x** (2026-07) — **Pattern 12 — Cloisonnement par outils** (« un juge n'écrit jamais / un worker n'escalade jamais », garanties au niveau `tools:`) + convention `vf-internal: true`.
- **v2.4.0** (2026-07-08) — Template `debugger` : Phase 0 — Recherche Documentaire (ADR-045).
- **v2.5.0** (2026-07-16) — 5e skill **`metier-orchestration`** (boucle de mission de l'orchestrateur métier) + `orchestrator-template.md` (ADR-048).
- **v2.5.1** (2026-07-25) — Déduplication du template skill-creator (pointeur vers le module canonique), sauvetage `adr-template.md`, scission ADR-031/ADR-056 répercutée.

Détail complet : voir `CHANGELOG.md` (module) et `content/VERSION.md` (version distribuée).

---

## Pour les modules vibeflow-os

Les modules `consolidator`, `infrastructure-audit`, `validator` du repo vibeflow-os référencent les patterns de cette doc :

- `consolidator` implémente le pattern 02-registres + 06-capitalisation
- `infrastructure-audit` complémente le pattern 11-halt-conditions
- `validator` orchestre tous les patterns via les skills outillés

Le pattern 12-cloisonnement-outils est le support doctrinal des équipes d'agents (team-kernel, mobile-test-team) et de la convention `vf-internal: true`.

Cette doc est donc la **source de vérité conceptuelle**, les autres modules sont les **outils opérationnels**.

---

## Limites

- 32 LRN orphelins dans certains templates registres (BLK-005 du Lab) — héritage à compléter
- VIBEFLOW_PHILOSOPHY.md et VIBEFLOW_EXPLAINED.md à actualiser pour pleinement refléter v4.1/v4.2
- Skills templates (debugger, agent-density-auditor, safe-execute, metier-orchestration) sont des copies — toute évolution dans les modules vibeflow-os respectifs doit être resync'ée ici (skill-creator est déjà un pointeur vers le module canonique depuis v2.5.1)

---

## Liens

- `content/methodology/VIBEFLOW_CORE.md` — Bible v4.2
- ADR-032 (Lab) — Pattern 02-registres opérationnalisé dans consolidator
- ADR-033 (Lab) — Distribution via vibeflow-os
