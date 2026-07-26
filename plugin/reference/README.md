# reference — Documentation Méthodologique VibeFlow

> **Module doc-only** : référence canonique de la méthodologie VibeFlow.
> 70 fichiers (608 KB) — méthodologie + 11 patterns + 4 skills + 33 templates + 1 exemple complet.

**Version** : v2.5.1 (release majeure mai 2026 — alignement VibeFlow Core v4.1)
**Source** : `distributions/VibeFlow-Reference-v2/VibeFlow-Reference-v2.0.zip`

---

## Quoi

Documentation complète de la méthodologie VibeFlow, distribuable et utilisable comme référence dans n'importe quel lab. Contient :

```
content/
├── README-CLIENT.md                       # Présentation pour utilisateur final
├── VERSION.md                              # Détail v2.0
├── LICENSE.md                              # Licence d'usage personnel
├── methodology/
│   ├── VIBEFLOW_CORE.md                    # Bible méthodologique v4.1 (8 principes P1-P8)
│   ├── VIBEFLOW_PHILOSOPHY.md              # Philosophie
│   ├── VIBEFLOW_EXPLAINED.md               # Vulgarisation avec analogies
│   ├── AXIOMES-ENFORCEMENT.md              # 3 axiomes transverses (enforcement>prose, filet fonctionnel, preuve avant done)
│   ├── patterns/                           # 11 patterns architecturaux universels
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
│   │   └── 11-halt-conditions.md
│   ├── vocabulary/                         # Lexique + forks-mapping + dire/ne-pas-dire
│   └── templates/                          # 33 templates génériques
│       ├── memory/ (5)
│       ├── agents/ (8 + contracts)
│       ├── triggers/ (5)
│       ├── rules/ (1)
│       ├── docs/ (5)
│       └── skills/ (4 : agent-density-auditor, skill-creator, safe-execute, debugger)
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

## Changelog v1.1 → v2.0

Saut majeur : alignement VibeFlow Core v4.0 → **v4.1**.

**Ajouts** (Session 044+ amendée du Lab) :
- 7 zones additives dans `VIBEFLOW_CORE.md` (charte densité agents, architecture skills natif, garde-fou runtime, Adversarial Plan-Review, Iron Law fresh-evidence, méta-procédures, halt conditions)
- 3 nouveaux patterns (09, 10, 11)
- Lexique enrichi (+16 termes v4.1)
- 4 skills (vs 1 en v1.1) : debugger, agent-density-auditor, safe-execute, skill-creator
- 8 agents refondus ≤ 250L (charte ADR-029)

Détail complet : voir `content/VERSION.md`.

---

## Pour les modules vibeflow-os

Les modules `consolidator`, `infrastructure-audit`, `validator` du repo vibeflow-os référencent les patterns de cette doc :

- `consolidator` implémente le pattern 02-registres + 06-capitalisation
- `infrastructure-audit` complémente le pattern 11-halt-conditions
- `validator` orchestre tous les patterns via les skills outillés

Cette doc est donc la **source de vérité conceptuelle**, les autres modules sont les **outils opérationnels**.

---

## Limites v2.0.0

- 32 LRN orphelins dans certains templates registres (BLK-005 du Lab) — héritage à compléter
- VIBEFLOW_PHILOSOPHY.md et VIBEFLOW_EXPLAINED.md à actualiser pour pleinement refléter v4.1
- Pattern 11-halt-conditions doit être intégré avec `infrastructure-audit` Session future

---

## Liens

- `content/methodology/VIBEFLOW_CORE.md` — Bible v4.1
- ADR-032 (Lab) — Pattern 02-registres opérationnalisé dans consolidator
- ADR-033 (Lab) — Distribution via vibeflow-os
