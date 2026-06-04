# dev-orchestrator — Orchestrateur de développement (VFDO)

> Module VibeFlow qui route les requêtes de développement en **langage naturel** vers les
> bons skills GSD/Superpowers installés — via un **agent routeur**, des **verbes `/vf-*`** et
> un **index factuel auto-généré**. L'utilisateur ne parle que VibeFlow ; la plomberie
> GSD/Superpowers reste invisible.

**Version** : v1.0.0
**Type** : agent + multi-skills + scripts

---

## Vue d'ensemble

Dire « aide-moi à dev », « code ça », « on est où ? » ou « débugge ce crash » déclenche le
pipeline de développement complet **sans jamais connaître GSD ni Superpowers**. Le module
fournit trois briques complémentaires :

1. **Agent `vibeflow-dev`** (`AGENT.md`) — le cerveau routeur. Il porte la table de routage
   canonique (intention NL → action coulisse), l'ordre du pipeline et les garde-fous. Il
   reformule toutes les sorties en vocabulaire VibeFlow (rapport de sprint, feuille de route…).
2. **Verbes `/vf-*`** (`skills/vf-*/`) — points d'entrée utilisateur explicites
   (`vf-dev`, `vf-plan`, `vf-execute`, `vf-test`, `vf-review`, `vf-debug`, `vf-ship`,
   `vf-auto`, `vf-progress`, `vf-quick`, `vf-brainstorm`, `vf-init`). Chaque verbe délègue à
   une cible canonique unique et partage exactement les mêmes cibles que l'agent.
3. **Scripts** (`scripts/`) — bootstrap et indexation :
   - `ensure-deps.sh` : auto-install non-interactif et **idempotent** de GSD + Superpowers
     (fallback manuel si Node/npm ou CLI `claude` manquent — jamais d'échec silencieux).
   - `build-gsd-index.sh` : génère un **index factuel** des skills GSD installés
     (100 % auto-généré depuis le frontmatter sur disque — D4, anti-hallucination).

---

## Structure du module

```
dev-orchestrator/
├── AGENT.md                       # agent vibeflow-dev (≤250L, dense)
├── skills/vf-*/SKILL.md           # 12 verbes utilisateur /vf-* (≤500L chacun)
├── scripts/
│   ├── ensure-deps.sh             # bootstrap deps (idempotent, dry-run testable)
│   ├── build-gsd-index.sh         # index factuel (VF_INDEX_OUT surchargeable)
│   └── tests/test-dev-orchestrator.sh  # suite de vérification (4 axes + densité)
└── references/                    # doctrine + index chargés on-demand par l'agent
    ├── GSD-PIPELINE.md
    ├── gsd-skills-index.md         # auto-généré (NE PAS ÉDITER)
    └── vocabulary-map.md
```

---

## Installation (via vibeflow-update.sh)

```bash
# depuis votre lab
.claude/scripts/vibeflow-update.sh install dev-orchestrator
```

L'installeur pose, de bout en bout :

- l'agent → `.claude/agents/dev-orchestrator.md`
- les verbes `/vf-*` → `.claude/skills/vf-*/`
- les scripts → `.claude/scripts/` (+ tests)
- les références (**D7**) → `.claude/agents/dev-orchestrator-references/`
  (`GSD-PIPELINE.md`, `gsd-skills-index.md`, `vocabulary-map.md`)
- un **index frais** : à l'install, `build-gsd-index.sh` est ré-exécuté avec
  `VF_INDEX_OUT=.claude/agents/dev-orchestrator-references/gsd-skills-index.md` (IDX-02).
  Best-effort : si GSD est absent, l'install n'échoue pas — l'index sera régénéré plus tard.

> **Note D7** — les références d'un module agent sont installées sous
> `.claude/agents/<mod>-references/`, pas sous `.claude/skills/`. L'agent les charge
> on-demand (densité préservée : l'`AGENT.md` n'embarque que l'ordre du pipeline).

---

## Usage

### Langage naturel (recommandé)

L'utilisateur parle normalement ; l'agent `vibeflow-dev` route :

| Vous dites… | Coulisse (invisible) |
|---|---|
| « réfléchis à… », « et si on… » | exploration / idéation |
| « planifie », « cadre cette feature » | cadrage puis plan de travail |
| « code ça », « implémente la feature X » | exécution du plan |
| « teste », « ça marche ? » | recette |
| « relis », « audit » | revue de code |
| « ça plante », « débugge » | dépannage |
| « fais tout en autonomie » | mode autonome |
| « livre », « crée une PR » | livraison |
| « on est où ? », « la suite » | point d'avancement |

### Verbes explicites `/vf-*`

Pour invoquer directement : `vf-init` (bootstrap), `vf-brainstorm`, `vf-plan`,
`vf-execute`, `vf-quick`, `vf-test`, `vf-review`, `vf-debug`, `vf-auto`, `vf-ship`,
`vf-progress`, `vf-dev` (aiguilleur générique).

### Bootstrap des dépendances

`vf-init` (ou l'agent au premier contact) lance `ensure-deps.sh` : auto-install
non-interactif de GSD + Superpowers, idempotent. `gsd-new-project` n'est **jamais** lancé
seul — uniquement proposé sur confirmation explicite (BOOT-04).

---

## Tests

```bash
bash dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
```

Couvre 4 axes (VERIF-01) — index non vide, idempotence `ensure-deps`, ≥11 intentions routées
vers des cibles distinctes, aucun mapping `/vf-*` orphelin — plus les gates de densité
(VERIF-02 : agent ≤250L, skills ≤500L, mesurés par `wc -l`). Exit 0 si tout passe
(les SKIP, ex. GSD absent, ne font pas échouer la suite).

---

## Références

- ADR / spec : `docs/superpowers/specs/2026-06-04-dev-orchestrator-design.md`
- D3 : auto-install des deps, init sur confirmation seulement
- D4 : index 100 % auto-généré (anti-hallucination)
- D7 : références d'un module agent sous `.claude/agents/<mod>-references/`
- IDX-02 : index régénéré à l'install via `VF_INDEX_OUT`
