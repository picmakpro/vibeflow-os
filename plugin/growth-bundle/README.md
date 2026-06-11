# growth-bundle — Bundle métier Growth / Acquisition (GrowthFlow)

> **Module doc-only** du plugin vibeflow-os.
> Il ne s'exécute pas seul : il porte des **blueprints** (agents + extension de domaine + registres)
> que le skill `vf-new-lab` (module `conductor`) lit pour **instancier un lab growth complet et gouverné**.

**Version** : v1.0.0 — **Type** : `doc-only` — **Requiert** : `planning-core`, `consolidator`,
`audit-architecture`, `validator`.

---

## Quoi

Un bundle métier capitalise tout ce qu'il faut pour monter un lab VibeFlow dans un métier donné —
ici le **growth / acquisition** — sans repartir de zéro et sans aucune hypothèse « dev ».

Pourquoi `doc-only` et pas un module multi-agents ? Parce que l'installeur du plugin ne gère **qu'un
seul `AGENT.md` par module**. Un bundle qui embarque 3 agents métier serait donc impossible à
installer comme module-agent classique. La solution tranchée à l'audit : le bundle est un **paquet de
documentation portant des blueprints**, et c'est `vf-new-lab` qui **instancie** chaque blueprint en
agent natif (`.claude/agents/<nom>.md`, ≤250L) dans le lab cible. Un blueprint = une spécification
complète prête à devenir un agent ; il n'est jamais exécuté tel quel.

## Pour quel métier

Pour tout lab dont la valeur cœur est **acquérir des clients** via des canaux d'acquisition :
cold email, LinkedIn Ads, SEO, partenariats, etc. La logique centrale du bundle est l'organisation
**PAR CANAL** : chaque canal a sa propre déclinaison d'ICP, ses séquences/créatives, ses offres, ses
métriques et son journal d'expériences — pour comparer les canaux entre eux (CAC / ROAS) **sans
contamination** des apprentissages d'un canal vers un autre.

Vocabulaire natif du lab : **canal · séquence · ICP · offre · expérience · CAC · ROAS**.

## Comment `vf-new-lab` l'utilise

Quand l'utilisateur demande « crée un lab d'acquisition », `vf-new-lab` :

1. **Détecte** le métier growth et choisit ce bundle.
2. **Lit `content/BUNDLE.md`** (le manifeste) — il y trouve le métier, le profil planning, le nom de
   l'extension, le vocabulaire, la liste des 3 agents, les modules requis et le flux d'instanciation.
3. **Instancie chaque blueprint** de `content/agents/` en agent natif ≤250L dans `.claude/agents/`
   du lab (le savoir détaillé reste déporté dans des skills injectés via `skills:` — ADR-029).
4. **Scaffolde l'extension** `growth/` selon `content/domain/extension-spec.md` (niveau global +
   `channels/<canal>/` à 5 fichiers + `channels/_TEMPLATE/`).
5. **Pose les 5 registres** mémoire et le pont planning↔mémoire selon `content/registres.md`.
6. **Câble les auditeurs** : agent `vibeflow-validator` + skill `audit-architecture` (filet obligatoire).
7. **Stampe la version du framework** dans le lab (détection d'update ultérieure).

Le bundle **délègue l'orchestration** au module `conductor` (`vibeflow-conductor`) : il ne re-code
aucun orchestrateur. Les agents métier ne font pas l'orchestration de lab — ils escaladent.

## Contenu

```
growth-bundle/
├── module.json                          # Déclaration du module (doc-only, requires)
├── VERSION                              # v1.0.0
├── CHANGELOG.md                         # Historique
├── README.md                            # Ce fichier
└── content/
    ├── BUNDLE.md                        # MANIFESTE — lu par vf-new-lab (flux d'instanciation)
    ├── agents/
    │   ├── channel-strategist.blueprint.md     # Orchestrateur growth (opus)
    │   ├── copywriter-sequences.blueprint.md   # Rédaction séquences/créatives par canal (sonnet)
    │   └── campaign-analyst.blueprint.md        # Métriques + CAC/ROAS + expériences (sonnet)
    ├── domain/
    │   └── extension-spec.md            # Structure exacte de l'extension growth/ (par canal)
    └── registres.md                     # 5 registres canon + IDs + pont planning↔mémoire
```

## Châssis doctrine (rappel)

Ce bundle **référence** les principes Core (jamais ne les reduplique) : P1 Capitaliser, P3 Orchestrer
(l'orchestrateur ne produit jamais), P4 Clarifier avant d'exécuter, P5 Vérifier en boucle, P7
Transposer pas copier (vocabulaire métier natif), P8 Évaluer (gate d'audit), P9 Modulariser (≤250L).
Détail canonique : module `reference` (`VIBEFLOW_CORE.md`).

## Garde-fous métier embarqués

- **RGPD prospects (critique)** : aucune donnée perso de prospect dans les `.md` du lab, aucun export
  hors outil source, aucune transmission à un LLM externe sans validation. Inscrit dans les INTERDITS
  du `CLAUDE.md` du lab à l'instanciation.
- **Seuils CAC/ROAS** déclarés par canal : CIBLE vs ALERTE-rouge (kill) / ALERTE-orange (itérer).
- **Tag-canal obligatoire** dans chaque LEARNING (zéro contamination inter-canaux).
- **Gate `audit-architecture`** : verdict bloquant anti-slop avant tout lancement de campagne.
