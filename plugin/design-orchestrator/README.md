# design-orchestrator — Le cycle design piloté en langage naturel

> Dire « c'est moche », « on part sur quel style ? » ou « refais toute l'app » suffit : le module
> traduit l'intention design en le bon workflow — sans que l'utilisateur ait à connaître la
> chaîne d'outils qui travaille en coulisse.

**Type** : agent + skills + équipe de mission · **Version** : v1.5.2 · **Dépend de** : `conductor`

---

## Quoi

Le point d'entrée design de VibeFlow, pour tout lab qui a une interface à concevoir, améliorer ou
critiquer — **quelle que soit la stack** (web, mobile, desktop). Le module fournit :

1. **L'agent `vibeflow-design`** (opus) — le cerveau routeur : table de routage langage naturel →
   geste design, doctrine (DA avant refonte, diagnostic avant geste, vérification après craft),
   généricité multi-stack. Il produit des **specs + tokens** adaptés à la stack détectée
   (variables CSS · tokens Swift · theme object RN/Flutter · tokens neutres), jamais du code
   framework-locké imposé.
2. **Les verbes `/vf-design` et `/vf-sketch`** — délégateurs minces auto-invocables. `/vf-design`
   est la porte design unique (DA, refonte, critique, craft ciblé — le contrat UI et la revue UI
   y sont routés en interne) ; `/vf-sketch` couvre la **maquette jetable** (« montre-moi à quoi ça
   ressemblerait »), seul geste assez spontané pour mériter sa propre porte.
3. **L'équipe de mission design** — première instanciation **non-dev** du team-kernel du conductor
   (ADR-053) : `vf-design-manager` (opus) planifie en DAG et dispatche `vf-crafter` (production)
   et `vf-design-judge` (critique scorée /100) en parallèle sur écrans disjoints. Le « vert »
   design = **score du juge ≥ 70/100 contre la DA**, 3 tours max de craft → re-critique par écran.
4. **Les références on-demand** — workflow quotidien, initialisation de la DA, chaîne d'outils +
   dégradation gracieuse, table de reframe, templates.

La chaîne d'outils réelle (référentiel UX, direction créative, atelier de craft, exploration —
plugins tiers mappés dans `references/design-toolchain.md`) reste **invisible côté utilisateur** :
l'agent reframe toute sortie en vocabulaire VibeFlow et dégrade sur les premiers principes design
si un outil manque.

---

## Installation

Cas normal : le module est **installé d'office avec `dev-orchestrator`** (il figure dans ses
`requires`) — tout lab de développement a `/vf-design` sans action supplémentaire. Sinon, via
l'installeur (`/vibeflow-install`, résolution des dépendances assurée) ou l'engine directement :

```bash
bash plugin/_internal/vibeflow-update.sh [--scope user|project|local] install --with-deps design-orchestrator
```

⚠️ En **install nu** (sans `--with-deps`), la résolution des `requires` n'est pas automatique :
installer dans l'ordre la fermeture de `conductor` (déclarée dans les `module.json`) —

```bash
bash plugin/_internal/vibeflow-update.sh install planning-core
bash plugin/_internal/vibeflow-update.sh install validator
bash plugin/_internal/vibeflow-update.sh install skill-creator
bash plugin/_internal/vibeflow-update.sh install conductor
bash plugin/_internal/vibeflow-update.sh install design-orchestrator
```

La chaîne d'outils design (plugins tiers) n'est **pas** une dépendance dure : absente, l'agent
dégrade gracieusement et le signale dans son rapport final.

---

## Démarrer — la DA en 5 minutes

Le premier geste d'un lab design est de poser la **direction artistique** (bible visuelle). Dans
un projet avec le module installé, dis simplement :

> « On part sur quel style ? » — ou « Définis l'identité visuelle du projet »

Ce qui se passe : l'agent `vibeflow-design` déroule **DA-INIT** — exploration du produit,
détection de la stack, proposition de directions, puis production de trois artefacts :

1. **`DESIGN.md`** — la bible visuelle du projet (palette, typo, spacing, ton) ;
2. une **section design dans `CLAUDE.md`** — pour que tout agent la respecte ensuite ;
3. le **système de design incarné selon la stack** (variables CSS, tokens Swift, theme object…).

À partir de là, le quotidien est couvert : « c'est moche, améliore cet écran » déclenche
critique → plan → craft → vérification, toujours **contre cette DA**.

---

## Usage

| Tu dis… | Ce qui se déclenche |
|---|---|
| « définis la DA / on part sur quel style / from scratch » | **DA-INIT** → bible visuelle + système de design |
| « rends ça plus beau / c'est moche / modernise / refais cette page » | **DESIGN-WORKFLOW** — routing par complexité (QUICK FIX / PLAN MODE / FULL DESIGN) |
| « audite / critique cet écran / qu'est-ce qui cloche / c'est pro ? » | **DESIGN-WORKFLOW** intent CRITIQUE — revue heuristique scorée |
| « le spacing / la typo / le contraste / une animation » | craft ciblé (QUICK FIX) |
| « explore / inspiration / cherche une direction » | intent INSPIRATION — exploration structurée |
| « extrais un design system / harmonise les composants » | build système (tokens) |
| « maquette-moi ça / montre-moi à quoi ça ressemblerait » | **`/vf-sketch`** — maquette jetable, on choisit puis on jette |
| « refais toute l'app / tous les écrans / refonte complète » | signal **mission design** → l'agent **propose** l'équipe (`vf-design-manager`) — jamais d'office |

**Enchaînement typique** : `/vf-sketch` (on voit les options) → `/vf-design` (on cadre et on
craft) → cycle de développement (`gsd-execute-phase`) pour construire pour de vrai.

**Frontières** : le jetable **visuel** → `/vf-sketch` · le jetable **fonctionnel** (question
technique) → `gsd-spike` · la construction une fois la direction validée → `gsd-execute-phase`.

---

## Référence

| Fichier | Rôle |
|---|---|
| `AGENT.md` | Agent routeur `vibeflow-design` (opus, memory project) — table de routage, doctrine, généricité, garde-fous |
| `skills/vf-design/SKILL.md` | Verbe `/vf-design` — porte d'entrée design (route aussi contrat UI + revue UI en interne) |
| `skills/vf-sketch/SKILL.md` | Verbe `/vf-sketch` — maquette jetable (délègue à `gsd-sketch`) |
| `agents/vf-design-manager.md` | Manager de mission (opus) — plan de bataille DAG, lock driver, dispatch parallèle, digest ≤ 30 lignes, halt conditions. Ne produit jamais de design |
| `agents/vf-crafter.md` | Worker de production (sonnet, interne) — UN écran à la fois via la chaîne d'outils, specs + tokens. Sans Task |
| `agents/vf-design-judge.md` | Juge frais (sonnet, interne) — rubric /100 : conformité DA /40 + 6 dimensions /10 (copy, hiérarchie, couleur, typo, spacing, a11y). Sans Write/Edit |
| `references/DESIGN-WORKFLOW.md` | Workflow quotidien — routing par intent et par complexité, checklists, gate de sortie |
| `references/DA-INIT.md` | Initialisation de la direction artistique |
| `references/design-toolchain.md` | Mapping reframe → plugins réels + vérification de présence + dégradation gracieuse |
| `references/design-vocabulary-map.md` | Table de reframe (plomberie → vocabulaire VibeFlow) |
| `references/templates/DESIGN.md` | Template de bible visuelle (rôles stables, incarnation par stack) |
| `references/templates/CLAUDE-design-section.md` | Template de section design pour `CLAUDE.md` |
| `scripts/ensure-design-deps.sh` | Vérification présence + activation, auto-install/enable non-interactif des 4 plugins de la chaîne design — déclenché à l'install/update du module (hook engine) et au premier contact de l'agent |
| `scripts/tests/test-design-orchestrator.sh` | Suite de tests — conformité des 3 agents (check-agents --strict), cloisonnement par tools (Pattern 12), densité ADR-029, câblage kernel, heuristique de routage, `ensure-design-deps.sh` (idempotence, scope, présence+activation, dégradation, autonomie, câblage double) |

---

## Limites

- **Produit des specs, pas l'écran final** : la construction réelle passe par le cycle de
  développement (`gsd-execute-phase`). Le module cadre, critique et crafte.
- **La chaîne d'outils n'est pas embarquée** : référentiel UX, direction créative et atelier de
  craft restent des plugins tiers. Leur **présence et leur activation** sont désormais vérifiées
  et rétablies automatiquement (`ensure-design-deps.sh`, présence + enabled/disabled) ; la
  dégradation gracieuse sur les premiers principes reste le filet quand l'install échoue ou que
  la CLI `claude` est absente, et l'agent le signale.
- **Couverture inégale par stack** : le référentiel UX couvre web + mobile ; direction créative et
  atelier de craft sont **web only**. Sur SwiftUI/Flutter, le craft repose davantage sur les
  premiers principes.
- **Le « vert » design est un jugement scoré, pas un test automatique** : la rubric /100 borne la
  subjectivité mais ne la supprime pas. Seuil (70/100) et budget (3 tours/écran) sont ajustables
  par brief.
- **L'équipe est proposée, jamais imposée** : un refus (ou un écran unique) → workflow direct
  inline, sans manager.
