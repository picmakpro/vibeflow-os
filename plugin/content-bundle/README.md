# content-bundle — Bundle métier ContentFlow

> Module **doc-only** du plugin vibeflow-os. Il transforme un lab VibeFlow générique en **studio
> éditorial gouverné** : une chaîne de production de contenu **brief → livrable → distribution**,
> avec ses agents métier, son socle planning, son extension de domaine et son filet d'audit.

---

## Pourquoi un bundle, et pas un agent ?

L'installeur vibeflow-os ne gère **qu'un seul `AGENT.md` par module**. Or ce métier a besoin de
**3 agents** (stratège, rédacteur, repurposer). On ne peut donc pas le livrer comme un module-agent.

La solution : un module **doc-only** qui porte des **blueprints** (spécifications d'agents complètes,
prêtes à instancier). Ce n'est pas le bundle qui crée les agents : c'est `vf-new-lab` (skill du module
`conductor`) qui **lit ce bundle** et **instancie** chaque blueprint en agent natif `≤250L` dans le
`.claude/agents/` du lab cible. Le bundle est la **recette**, `vf-new-lab` est le **cuisinier**.

## Pour quel métier

**Content / création de contenu (ContentFlow)** — toute personne ou équipe qui produit du contenu de
façon récurrente : newsletters, posts LinkedIn, threads, scripts vidéo courts, carrousels. Le bundle
matérialise la chaîne éditoriale complète : cadrer l'angle → produire le livrable → décliner et
distribuer, le tout sous une ligne éditoriale tenue et un sourcing gouverné.

| Caractéristique | Valeur |
|---|---|
| Métier | content / éditorial (chaîne brief → livrable → distribution) |
| Profil planning | **standard** |
| Extension de domaine | **`editorial/`** |
| Vocabulaire natif | campagne · pièce · angle · pilier · cadence |
| Agents | strategist · scriptwriter · repurposer (3, sonnet, ≤250L chacun) |
| Filet d'audit | `vibeflow-validator` + `audit-architecture` (gate de clarté bloquant) |

## Comment `vf-new-lab` l'utilise

1. L'utilisateur lance `vf-new-lab` (« monte-moi un lab de contenu »).
2. `vf-new-lab` détecte le métier *content* et **lit `content/BUNDLE.md`** de ce module.
3. Il dérive le profil planning (**standard**) et l'extension (**`editorial/`**) — confirmés par le
   manifeste.
4. Il **instancie les 3 blueprints** (`content/agents/*.blueprint.md`) en agents natifs `≤250L` dans
   `.claude/agents/` du lab, en injectant les skills déclarés via le frontmatter `skills:`.
5. Il **scaffolde l'extension** `editorial/` selon `content/domain/extension-spec.md` et pose les
   **5 registres** canon selon `content/registres.md`.
6. Il **câble le filet** : agent `vibeflow-validator` + skill `audit-architecture` (gate de clarté).
7. Il **stampe la version framework** dans le lab pour la détection d'update ultérieure.

> Le détail séquentiel exact est dans `content/BUNDLE.md` (section « Flux d'instanciation »). Ce
> bundle est conçu pour être consommé par `vf-new-lab` ; il peut aussi se lire manuellement comme
> guide de montage d'un studio éditorial gouverné.

## Contenu du module

```
content-bundle/
  module.json                       Manifeste de module (doc-only, dépendances)
  VERSION                           v1.0.0
  CHANGELOG.md                      Historique
  README.md                         Ce fichier
  content/
    BUNDLE.md                       ★ MANIFESTE — métier, profil, agents, FLUX D'INSTANCIATION
    agents/
      strategist.blueprint.md       Blueprint agent stratège éditorial (sonnet, ≤250L)
      scriptwriter.blueprint.md     Blueprint agent rédacteur/idéateur (sonnet, ≤250L)
      repurposer.blueprint.md       Blueprint agent repurposing/distribution (sonnet, ≤250L)
    domain/
      extension-spec.md             Structure exacte de l'extension editorial/ à scaffolder
    registres.md                    5 registres canon + IDs + capitalisation + pont planning↔mémoire
```

## Dépendances

`planning-core` (socle `.planning/`), `consolidator` (consolidation mémoire + promotion de
décisions), `audit-architecture` (gate de clarté, P8), `validator` (agent `vibeflow-validator`).
Orchestration assurée par le module `conductor` — **le bundle ne re-code aucun orchestrateur**.

## Châssis doctrinal

Ce bundle **référence** les principes Core (P1, P3, P4, P5, P7, P8, P9 — source : module `reference`)
sans jamais les redupliquer. Il respecte la charte densité **ADR-029** (agents ≤250L, savoir en
skills), le **pont planning↔mémoire** à propriétaire unique, et la règle **« pas de lab sans
filet »** (auditeurs toujours câblés). Détail dans `content/BUNDLE.md` et `content/registres.md`.
