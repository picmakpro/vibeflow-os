# Spec — Module `dev-orchestrator/` (VibeFlow → GSD + Superpowers)

> Date : 2026-06-04
> Statut : design validé (brainstorming), prêt pour phase GSD
> Repo : vibeflow-os

## 1. Vision

L'utilisateur installe **uniquement VibeFlow**. À partir de là, tout le développement
technique est piloté par un agent dev-expert qui orchestre **GSD** et **Superpowers**
en coulisse. L'utilisateur parle un vocabulaire 100% VibeFlow et n'a jamais besoin de
savoir que GSD ou Superpowers existent. Si ces dépendances manquent, elles sont
installées automatiquement.

**Objectif mesurable** : depuis une install VibeFlow fraîche, un utilisateur qui dit
« aide-moi à dev cette feature » obtient le pipeline GSD complet (brainstorm → plan →
execute → test) sans jamais taper une commande `gsd-*` ni connaître son existence.

## 2. Décisions structurantes (verrouillées)

| # | Décision | Choix |
|---|----------|-------|
| D1 | Forme & distribution | Nouveau module `dev-orchestrator/` dans vibeflow-os, distribué via `vibeflow-update.sh` |
| D2 | Modèle d'abstraction | Hybride : agent route le langage naturel par défaut **+** set complet de verbes `/vf-*` |
| D3 | Bootstrap | Install auto des dépendances ; init projet (`new-project`/`map-codebase`) **sur confirmation** |
| D4 | Index des skills GSD | **100% auto-généré** (factuel) ; l'ordre du pipeline + bonnes pratiques **documentés dans l'agent** |
| D5 | Définition de l'agent | `AGENT.md` (confirmé : `vibeflow-update.sh` le copie en `.claude/agents/<mod>.md`, format subagent natif Claude Code — cf. `validator/`) |
| D6 | Couverture verbes | **Maximale** : routage NL le plus large + commandes `/vf-*` invocables par l'agent lui-même en autonomie |

## 3. Structure du module

```
dev-orchestrator/
├── README.md
├── AGENT.md                      # agent vibeflow-dev — copié en .claude/agents/dev-orchestrator.md
├── references/
│   ├── GSD-PIPELINE.md           # ordre canonique + bonnes pratiques (chargé on-demand, règle 1%)
│   └── gsd-skills-index.md       # AUTO-GÉNÉRÉ par build-gsd-index.sh — NE PAS éditer
├── skills/
│   ├── vf-dev/                   # point d'entrée générique : route une demande dev
│   ├── vf-brainstorm/            # → superpowers brainstorming
│   ├── vf-plan/                  # → gsd-discuss-phase + gsd-plan-phase
│   ├── vf-execute/               # → gsd-execute-phase
│   ├── vf-quick/                 # → gsd-quick (tâche mineure)
│   ├── vf-test/                  # → gsd-verify-work
│   ├── vf-review/                # → gsd-code-review
│   ├── vf-debug/                 # → gsd-debug
│   ├── vf-auto/                  # → gsd-autonomous
│   ├── vf-ship/                  # → gsd-ship
│   ├── vf-progress/              # → gsd-progress
│   └── vf-init/                  # bootstrap : ensure-deps + offre d'init projet
└── scripts/
    ├── ensure-deps.sh            # détecte + installe GSD (npm) + superpowers (plugin), idempotent
    ├── build-gsd-index.sh        # parse les SKILL.md/workflows GSD → references/gsd-skills-index.md
    └── tests/test-dev-orchestrator.sh
```

## 4. Composant — Agent `vibeflow-dev` (le cerveau routeur)

Subagent Claude Code natif (`AGENT.md` → `.claude/agents/dev-orchestrator.md`).
Lean : **≤250 lignes** (charte densité VibeFlow). Contenu :

- **Persona** : expert dev senior qui pilote GSD/superpowers en coulisse et ne nomme
  jamais « GSD » à l'utilisateur.
- **Table de routage langage naturel → action** (couverture maximale des formulations) :

| Intention utilisateur (exemples de formulations) | Action en coulisse |
|---|---|
| « réfléchis à / conçois / on part sur quoi / aide-moi à penser » | superpowers `brainstorming` |
| « planifie / prépare / découpe / cadre la phase » | `gsd-discuss-phase` + `gsd-plan-phase` |
| « code / implémente / ajoute / construis / fais » | `gsd-execute-phase` (ou `gsd-quick` si trivial) |
| « petite tâche / vite fait / corrige ce typo » | `gsd-quick` / `gsd-fast` |
| « teste / vérifie que ça marche / valide » | `gsd-verify-work` |
| « relis le code / audit / review » | `gsd-code-review` |
| « débugge / ça plante / pourquoi ça marche pas » | `gsd-debug` |
| « fais tout / en autonomie / pendant la nuit / débrouille-toi » | `gsd-autonomous` |
| « crée une PR / livre / ship » | `gsd-ship` |
| « on est où / et après / next » | `gsd-progress` |
| « comprends ce code / cartographie » | `gsd-map-codebase` |

- **Doctrine pipeline embarquée (D4)** : l'ordre canonique GSD
  `new-project → map-codebase → discuss-phase → plan-phase → execute-phase →
  verify-work → code-review → ship → complete-milestone`, le chemin autonome
  (`gsd-autonomous`), les escape hatches (`quick`/`fast`), quand faire `/clear`,
  les model profiles. Le détail exhaustif est déporté dans `references/GSD-PIPELINE.md`
  (chargé on-demand pour respecter la densité de l'agent).
- **Garde-fous** : ne réimplémente jamais la logique GSD (délègue toujours) ; reframe
  les sorties en vocabulaire VibeFlow ; sur action structurante, applique P4 (clarifier)
  et P5 (vérifier).

## 5. Composant — Index auto-généré (`build-gsd-index.sh`)

- Parse chaque `SKILL.md` sous `~/.claude/skills/gsd-*` (frontmatter `name` + `description`)
  et les workflows GSD → écrit `references/gsd-skills-index.md`.
- **Factuel uniquement** : noms et descriptions réels extraits du disque → zéro
  hallucination de nom de skill, toujours synchronisé avec la version GSD installée.
- Ré-exécuté : (a) à l'install/update du module, (b) quand `infrastructure-audit`
  détecte un drift GSD.
- La **logique de routage et l'ordre pipeline NE sont PAS dans l'index** — ils vivent
  dans l'agent (section 4). L'index est la source factuelle, l'agent est l'intelligence.

## 6. Composant — Couche d'abstraction (hybride, D2/D6)

- **Défaut** : langage naturel → l'agent route (table section 4).
- **Set complet de commandes `/vf-*`** (section 3) : chaque commande est un skill **thin**
  (frontmatter + une instruction « invoque le skill GSD X, reframe la sortie en VibeFlow »).
  Double usage :
  1. **Utilisateur** : raccourcis explicites pour intentions fortes.
  2. **Agent** : handles nommés que `vibeflow-dev` invoque lui-même quand il pilote
     une exécution autonome (il enchaîne `/vf-plan` → `/vf-execute` → `/vf-test`).
- **Traduction de vocabulaire** : « SUMMARY.md de phase » → « rapport de sprint »,
  « ROADMAP » → « feuille de route », etc. L'utilisateur ne voit jamais « GSD ».

## 7. Composant — Bootstrap d'auto-installation (`ensure-deps.sh`, D3)

Branché sur `vibeflow-update.sh` (install du module) + garde-fou SessionStart léger :

1. Détecte GSD (`which gsd-sdk`) → si absent : `npm i -g get-shit-done-cc` (ou source équivalente).
2. Détecte Superpowers (plugin) → si absent : l'installe.
3. **Idempotent** : ne réinstalle pas si présent ; log clair de ce qui a été fait.
4. Si du code existe → `map-codebase` peut tourner automatiquement (non-interactif).
5. `gsd-new-project` (interactif) **ne se lance jamais seul** : l'agent propose
   « Je détecte un projet dev — je l'initialise ? » et n'agit que sur confirmation.

## 8. Vérification / qualité

- `tests/test-dev-orchestrator.sh` :
  - `build-gsd-index.sh` génère un index non vide depuis les skills GSD installés.
  - `ensure-deps.sh` est idempotent (2e run = no-op).
  - La table de routage couvre les ≥11 intentions (section 4).
  - Chaque `/vf-*` mappe vers une cible existante (skill GSD vérifié contre l'index
    généré, skill superpowers, ou bootstrap interne) — aucun mapping orphelin.
- Densité : agent ≤250L, skills ≤500L — gate `software-architecture/scripts/check-file-size.sh`.

## 9. Hors scope (YAGNI)

- Pas de réécriture/fork des skills GSD — on délègue, on n'absorbe pas.
- Pas de gestion multi-runtime (Copilot/Gemini) au-delà de ce que GSD fait déjà.
- Pas de traduction exhaustive de tous les artefacts GSD — seulement le vocabulaire
  exposé à l'utilisateur.

## 10. Comment c'est développé : phase GSD (dogfooding)

1. `gsd-new-project` léger sur vibeflow-os (ROADMAP/PROJECT) — `map-codebase` déjà fait.
2. Phase « dev-orchestrator » → `gsd-plan-phase` → `gsd-execute-phase` → `gsd-verify-work`.

Ce spec sert d'entrée (contexte) à la phase.
