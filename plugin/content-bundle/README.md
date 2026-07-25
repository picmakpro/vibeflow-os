# content-bundle — Équipe content sur le team-kernel (ContentFlow)

> Module **installable** du plugin vibeflow-os : la première équipe métier **non-dev** complète
> construite sur le team-kernel (manager → workers → juge). Il transforme un lab VibeFlow en
> **studio éditorial gouverné** : chaîne **brief → cadrage → rédaction → gate de clarté →
> validation humaine → déclinaison/distribution**, avec dispatch parallèle des pièces et
> publication toujours human-gated.

---

## Ce que le module installe

| Pièce | Rôle | Modèle | Cloisonnement |
|---|---|---|---|
| `vf-content-manager` | manager de mission : DAG + verrou de driver, dispatch parallèle des pièces indépendantes, digest par mandat, contrôle de flux sur rapports typés, orchestration de la validation humaine | opus | exposé — **ne produit jamais** (pas d'Edit, aucune écriture de contenu) |
| `vf-content-strategist` | fiche de cadrage : un angle unique justifié contre `AUDIENCE.md` et `LIGNE-EDITORIALE.md`, structure, format | sonnet | `vf-internal`, écrit uniquement `pieces/<slug>/cadrage.md` |
| `vf-content-writer` | 3 hooks + livrable complet, zéro chiffre non sourcé, auto-contrôle 4 critères | sonnet | `vf-internal`, écrit uniquement `pieces/<slug>/piece.md` |
| `content-clarity-judge` | juge frais du gate de clarté : rubric **/100**, seuil **80**, chiffre non sourcé **éliminatoire**, verdict typé | sonnet | `vf-internal`, **read-only** (tools sans Write/Edit) |
| `vf-content-repurposer` | déclinaisons multi-plateformes d'une pièce **verte** uniquement, un CTA par variante, tient `editorial/CALENDRIER.md` | sonnet | `vf-internal`, écrit uniquement `variantes.md` + `CALENDRIER.md` |
| skill `vf-content` | point d'entrée métier : geste simple vs mission (seuil 3 pièces / signal de durée) | — | — |

## La chaîne (et sa définition du « vert »)

```
BRIEF ─▶ vf-content-strategist ─▶ vf-content-writer ─▶ content-clarity-judge (≥80/100)
      ─▶ VALIDATION HUMAINE (jamais auto-validée) ─▶ vf-content-repurposer ─▶ humain publie
```

Une pièce n'est **verte** que si : gate de clarté auto-contrôlé passé + score du juge ≥ 80/100
sans critère éliminatoire + **validation humaine explicite**. La distribution est TOUJOURS
human-gated (ADR-031) : en mode autonome, la mission s'arrête à « prêt pour validation » —
le « human-validator » n'est pas un agent, c'est l'humain, orchestré par le manager
(statut `human_needed`).

## Deux régimes d'usage

- **Geste simple** (« écris un post », « décline cet article ») : le skill `vf-content`
  déroule la chaîne courte — un étage à la fois, gate + juge + validation humaine compris.
- **Mission** (≥ 3 pièces ou signal de durée : « la semaine », « en autonomie ») :
  `vf-content-manager` prend le pilotage — plan de bataille en DAG (5 nœuds par pièce),
  verrou de driver, **dispatch parallèle** des pièces indépendantes (périmètres d'écriture
  disjoints par construction : un dossier `pieces/<slug>/` par pièce), digest ≤ 30 lignes
  par mandat, halt conditions, rapport de mission avec file d'attente de validation.

## Prérequis côté lab

Le lab doit porter le référentiel éditorial (`.planning/editorial/` : `LIGNE-EDITORIALE.md`,
`CALENDRIER.md`, `AUDIENCE.md`, `FORMATS.md`, `PILIERS.md`) — posé par `vf-planning`
(profil standard) ou `vf-new-lab`. Le skill a un garde first-use : référentiel absent →
proposition de poser le socle d'abord (mode dégradé possible, signalé). Les scripts du
kernel (`dag.sh`, `driver-lock.sh`, `check-agents.sh`) viennent du module `conductor`
(socle obligatoire).

## Contenu du module

```
content-bundle/
  module.json                    agents + skill + scripts · proposable
  VERSION / CHANGELOG.md / README.md
  agents/
    vf-content-manager.md        ★ manager de mission (opus, team-kernel)
    vf-content-strategist.md     worker cadrage (sonnet, vf-internal)
    vf-content-writer.md         worker rédaction (sonnet, vf-internal)
    vf-content-repurposer.md     worker déclinaison/calendrier (sonnet, vf-internal)
    content-clarity-judge.md     juge frais read-only (sonnet, vf-internal)
  skills/
    vf-content/SKILL.md          point d'entrée métier (aiguillage simple vs mission)
  scripts/
    tests/test-content-bundle.sh suite machine (12 tests)
  content/                       ← TRACE DE CONCEPTION (matérialisée le 2026-07-25)
    BUNDLE.md                    manifeste d'origine, lu par vf-new-lab
    agents/*.blueprint.md        blueprints d'origine des 3 workers
    domain/extension-spec.md     structure exacte de l'extension editorial/
    registres.md                 5 registres canon + IDs + pont planning↔mémoire
```

## Vérification machine

```bash
bash plugin/content-bundle/scripts/tests/test-content-bundle.sh
bash plugin/conductor/scripts/check-agents.sh --strict --agents-dir=plugin/content-bundle/agents
```

La suite verrouille notamment : le juge sans Write/Edit, le manager sans périmètre de
production, le cloisonnement Pattern 12 des workers, les rapports typés + DIGEST, et la
**non-contournabilité de la validation humaine** (manager + repurposer + skill).

## Dépendances

`planning-core` (socle `.planning/` + extension `editorial/`), `consolidator` (registres,
promotion de décisions), `audit-architecture` (audit du process générateur, P8), `validator`
(filet de conformité). Kernel d'orchestration : module `conductor` (toujours présent).

## Châssis doctrinal

Team-kernel (`conductor-references/team-kernel.md`) : verrou de driver, DAG, rapports typés,
digest, halt conditions, cloisonnement par tools. Principes Core P1/P3/P4/P5/P7/P8/P9
référencés, jamais redupliqués. Densité ADR-029 (agents ≤ 250L, skill ≤ 500L), agents natifs
machine-enforced ADR-044, validation humaine ADR-031. Vocabulaire métier natif (P7) :
campagne · pièce · angle · pilier · cadence.
