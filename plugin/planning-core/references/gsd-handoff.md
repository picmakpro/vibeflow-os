# GSD-HANDOFF — Frontière d'altitude entre `planning-core` et le moteur de planning GSD

> Référence du skill `vf-planning`. Chargée **on-demand**, quand `detect-gsd-engine.sh` renvoie
> 0 ou 2, ou quand le jugement métier conclut « lab dev ».
>
> **Iron Law** : *« Un projet de code a un seul moteur de planning : GSD. VibeFlow tient l'altitude
> au-dessus (le lab) et la couche à côté (mémoire, enforcement) — jamais la même. »*

---

## Le test unique

Pour trancher n'importe quel geste : **est-ce que ça concerne un projet, ou le lab ?**

| Geste | Propriétaire |
|---|---|
| `PROJECT.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `MILESTONES.md`, `phases/NN/*`, `config.json`, `codebase/` d'un projet dev | **GSD** |
| Santé du `.planning/` d'un projet, learnings de phase, workstreams parallèles | **GSD** |
| `INDEX.md` du lab, typage `deliverable`/`continuous`, `BOARD.md`, seuil d'autonomie, dette de planning | **planning-core** |
| Promotion des décisions vers `.claude/memory/` (pont mémoire) | **planning-core** |
| Socle complet d'un lab **non-dev** | **planning-core** |
| `Stop` guard bloquant (`guard-planning-updated.sh`) | **planning-core** — exception motivée |

**Pourquoi le `Stop` guard est une exception** : il ne génère rien. Il vérifie une propriété du
*résultat* — « des livrables ont changé, le planning suit-il ? » — quel qu'en soit l'auteur, GSD ou
humain. Il ne concurrence donc aucun producteur, et GSD n'offre aucun équivalent bloquant.

## Table de redirection — intention → brique GSD

Sur un lab dev, ces intentions **ne sont pas traitées** par `vf-planning`. Elles partent à la
brique GSD correspondante (directement, ou via l'agent `vibeflow-dev` qui détecte l'intention).

| L'utilisateur demande | Rediriger vers |
|---|---|
| démarrer le projet, poser la charte, faire la feuille de route, lister les exigences | le démarrage de projet : `gsd-new-project` (garde-fou first-use de l'agent `vibeflow-dev`) |
| où en est-on, statut, avancement, la suite, next | `gsd-progress` |
| cadrer une étape, découper, préparer le sprint, planifier la feature | cadrage + plan : `gsd-discuss-phase` puis `gsd-plan-phase` |
| comprendre le code existant, cartographier, « c'est quoi ce repo » | `gsd-map-codebase` |
| clôturer un jalon, archiver le milestone, démarrer le suivant | `gsd-complete-milestone`, puis `gsd-new-milestone` |
| vérifier la santé du `.planning/`, réparer une incohérence | `gsd-health` |

Les skills `gsd-*` sont l'interface directe du moteur de planning dev ; sur une intention ambiguë,
l'agent `vibeflow-dev` tranche via la carte canonique
(chemin d'install D7 : `.claude/agents/dev-orchestrator-references/intent-routing.md`).

## Ce que `vf-planning` fait encore sur un lab dev

La **couche lab**, et rien d'autre :

1. `INDEX.md` du lab et son actualisation (tableau de bord qui POINTE vers les plans).
2. Typage des compartiments (`deliverable` / `continuous`) et application du seuil d'autonomie —
   voir `compartments.md`.
3. Surface de la dette de planning (`detect-planning-debt.sh`).
4. Pont mémoire vers `.claude/memory/` — voir `bridge-memory.md`.

Un compartiment dev reçoit son `.planning/` **écrit par GSD** (via `gsd-new-project` depuis ce
compartiment). `vf-planning` ne pose jamais le tronc d'un projet de code.

## Protocole de migration (exit 2)

`detect-gsd-engine.sh` renvoie 2 : un `.planning/` de facture `planning-core`
(`planning_version:`) coexiste avec des signaux de code.

1. **Ne rien réécrire.** Le contenu appartient à l'utilisateur (ADR-031). Aucun écrasement, aucune
   conversion de frontmatter automatique.
2. **Juger le métier d'abord** (`domain-detection.md`). Un lab de contenu qui héberge un site web
   déclenche un exit 2 et reste **non-dev** : dans ce cas, séquence universelle, fin de l'histoire.
3. **Si le lab est bien dev** : exposer le constat en langage utilisateur — « le suivi de ce projet
   est dans un format que l'outillage de développement ne sait pas lire » — et **proposer**
   `gsd-new-project` pour que le moteur reprenne la main.
4. **Ce qui se perd, le dire.** Les compteurs `progress.total_steps` et le champ `profile` n'ont pas
   d'équivalent GSD. Les décisions clés de `PROJECT.md` méritent d'être promues en mémoire (pont)
   **avant** la reprise. Le dire à l'utilisateur, le laisser décider.
5. **Aucune automatisation disponible** : `gsd-import --from` importe un plan isolé, pas un
   `.planning/` entier. La reprise est un geste humain assisté, pas un script.
