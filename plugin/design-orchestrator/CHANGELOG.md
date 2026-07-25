# CHANGELOG — design-orchestrator

## [v1.1.1] — 2026-07-25

### Modifié
- Suit la bascule agentique du dev-orchestrator v2.0.0 : les renvois vers les verbes dev supprimés pointent vers les briques gsd réelles ; le reframe dev est abandonné, la table de vocabulaire ne gouverne plus que la chaîne design.

## [v1.1.0] — 2026-07-25 (verbe `/vf-sketch` + démarcations croisées)

### Ajouté

- **Verbe `/vf-sketch`** (`skills/vf-sketch/`) — maquette jetable : « maquette-moi ça », « montre-moi
  à quoi ça ressemblerait », « esquisse deux ou trois variantes ». Délègue à l'outil de maquettage
  interne. C'est le **seul** geste design qui gagne une porte d'entrée propre, parce que
  l'utilisateur le formule spontanément ; le contrat UI et la revue UI restent routés en interne
  depuis `/vf-design`.

### Modifié

- **Description de `/vf-design`** réécrite sur le gabarit commun (formulations réelles,
  contre-exemples nommant les voisins, portée d'invocation) : le jetable **visuel** va à
  `/vf-sketch`, le jetable **fonctionnel** à `/vf-spike`, la construction à `/vf-execute`.
  Réciproquement, `/vf-sketch` repousse vers `/vf-design` et `/vf-spike`.
- **Corps de `/vf-design`** : il nomme désormais la chaîne interne qu'il porte (contrat UI, revue
  UI), qui n'a pas de verbe dédié — un test d'exhaustivité vérifie qu'aucune cible n'est promise
  par la doctrine de routage sans être réellement citée par le verbe qui la porte.
- **Vocabulaire** : le module ne parle plus d'« idéation » pour son exploration de directions
  visuelles — le mot appartient au verbe `/vf-explore` du module dev.

## [v1.0.0] — 2026-07-08

### Module initial

**Squelette du module** (conforme aux modules vibeflow-os : `VERSION`, `CHANGELOG.md`,
`README.md`, `module.json`, `AGENT.md`, `skills/`, `references/`)
- Type : **agent + skills**. Installé d'office avec `dev-orchestrator` (via ses `requires`).

**Agent routeur `vibeflow-design`** (`AGENT.md`, ≤250L, ADR-044 : description + model + memory)
- Table de routage langage naturel → geste design coulisse (DA-INIT / DESIGN-WORKFLOW par intent
  ACTION / INSPIRATION / CRITIQUE / craft ciblé).
- **Généricité multi-stack** : détection de stack, incarnation du système de design adaptée
  (web CSS/Tailwind · SwiftUI · React Native / Flutter · desktop). Produit des specs + tokens,
  jamais du code framework-locké.
- Doctrine : DA avant refonte, diagnostic avant geste, vérification après craft.
- Reframe systématique ; ne nomme jamais les outils design bruts.

**Verbe `/vf-design`** (`skills/vf-design/`)
- Thin delegator à description riche en wording (auto-invocation langage naturel), délègue à
  `vibeflow-design`. Point d'entrée design unique.

**Références on-demand** (`references/`)
- `DESIGN-WORKFLOW.md` — workflow quotidien (routing intent + complexité QUICK FIX / PLAN MODE /
  FULL DESIGN, checklists par mode, gate de sortie), générique multi-stack.
- `DA-INIT.md` — initialisation de la direction artistique (bible visuelle + section CLAUDE.md +
  système de design incarné selon la stack).
- `design-toolchain.md` — mapping reframe → plugins réels (`ui-ux-pro-max`, `frontend-design`,
  `impeccable`, `superpowers`), vérification de présence et **dégradation gracieuse**.
- `design-vocabulary-map.md` — table de reframe (outils design → vocabulaire VibeFlow).
- `templates/DESIGN.md` + `templates/CLAUDE-design-section.md` — templates génériques (rôles
  stables, incarnation selon stack).

### Origine
- Dérivé et généralisé depuis le kit `design-system-kit` (skills `design` + `design-init-da`,
  initialement Next.js/Tailwind/shadcn) — rendu **stack-agnostique** et aligné sur la doctrine
  VibeFlow (agent routeur + verbe thin + références on-demand + reframe).
