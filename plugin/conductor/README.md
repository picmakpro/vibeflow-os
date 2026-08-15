# conductor

> **Le socle de gouvernance du lab — et l'hôte du team-kernel.** Porte d'entrée pour tout ce qui
> touche la *configuration* du lab — créer, installer, vérifier, mettre à jour, migrer — dans
> **n'importe quel métier**. Pas appelé en continu : il intervient aux moments de config, d'audit
> et de migration. Module **mandatory** : posé d'office à chaque install, c'est lui qui porte les
> gates machine (hooks) et le noyau d'orchestration d'équipe réutilisé par tous les autres modules.

**Type** : `agent + skills + scripts + references` · **Version** : v1.22.0 · **Dépend de** : `planning-core`, `validator`, `skill-creator`.

> `skill-creator` est une dépendance **dure** depuis ADR-047 : c'est le canal unique de création de
> skills, invoqué par `vf-new-lab` en fan-out (Phase 5) et exigé par le Gate C. Le conductor étant
> mandatory, `skill-creator` est tiré d'office à chaque install (fermeture transitive `--with-deps`).

---

## L'agent `vibeflow-conductor` — 4 rôles

1. **Configurateur** — crée un lab depuis ton métier (`vf-new-lab`), pose les modules
   (`/vibeflow-install`), le socle planning (`vf-planning`).
2. **Vérificateur** — déclenche l'audit complet en déléguant à `vibeflow-validator` (5 phases).
3. **Calibreur** — détecte qu'une évolution du framework impacte le lab et pilote la migration
   (`vf-calibrate`), sous validation humaine (ADR-031).
4. **Gardien** — reçoit les escalades de cohérence des sous-agents (`references/contracts.md`),
   arbitre, route.

Il **route et délègue** — ne réimplémente jamais, ne fait jamais le travail métier.

## Le team-kernel — le noyau d'équipe transverse, hébergé ici

Extrait du dev-orchestrator (ADR-053, éprouvé en mission) et hébergé par le conductor **parce
qu'il est mandatory** : le pattern **manager → workers → juges** est ainsi disponible dans tout
lab, quel que soit le métier. Contrat complet : `references/team-kernel.md`.

Ce que le kernel fournit (invariant) :

| Brique | Support | Garantie |
|---|---|---|
| **Lock de driver** | `scripts/driver-lock.sh` (acquire / heartbeat / release, TTL + recovery) | une seule mission pilote à la fois ; reprise propre d'un lock périmé |
| **Plan de bataille en DAG** | `scripts/dag.sh` (init / add --deps **--scope** / ready / mark / reopen / status) | contrôle de flux déterministe ; la frontière `ready` se dispatche **en parallèle** sur périmètres disjoints ; `reopen` force `review_regime=full` sur tout nœud de revue/jointure rouvert (D-14, Phase 20) |
| **Rapports typés** (Pattern C) | `{ statut: passed\|gaps_found\|human_needed\|blocked, findings[], noeuds_debloques[] }` | fin du pilotage à la prose ; escalade humaine impérative sur `ask-user` |
| **Halt conditions** | 5 codes (boucle sans progrès, action destructive, ressource manquante, budget épuisé, drift de scope) | l'humain arbitre sur un message structuré |
| **Digest de mission** | ≤ 30 lignes par mandat, le disque fait foi | amortit les relectures de contexte |
| **Cloisonnement par tools** (P12) | juges via `disallowedTools: Write, Edit` (contrainte runtime, Phase 20), la plupart des workers sans Task, allowlist `Agent(...)` sur les managers, `vf-internal: true` | anti-triche vérifié par les suites de test des modules ET par `check-agents.sh`, qui linte désormais le contenu de `tools:` (syntaxe des allowlists `Agent(...)`/`Task(...)`, noms résolus) en plus du frontmatter (ADR-044, Phase 16) — un CONTRAT documenté, pas un cloisonnement runtime : le runtime ignore la liste de noms entre parenthèses pour tout agent dispatché en sous-agent, il ne l'applique qu'en incarnation fenêtre principale (`claude --agent`, doc officielle sub-agents). Le garant machine réel de « un seul manager actif », quel que soit le chemin de dispatch, est le verrou de driver — détail : `references/team-kernel.md` |

Chaque métier ne paramètre que ses spécialistes, sa définition de « vert » et ses gates. S'y
branchent aujourd'hui : **dev-orchestrator** (implémentation de référence, `vf-dev-manager`),
**mobile-test-team** (`vf-test-orchestrator`), **design-orchestrator** (`vf-design-manager`,
première instanciation non-dev) et les **bundles métier** (business-pilot, content, growth).

## Les 3 skills

- **`vf-new-lab`** — Lab Factory clarification-first : cadrage à gates machine (Gate A brief,
  Gate B capacités, Gate C conformité), manifeste de capacités, fan-out `skill-creator`, ficelage
  des auditeurs, assemblage. Mode **express** ≤ 15 min (3 questions, `[DÉRIVÉ]` assumé). Zéro
  hypothèse dev. Embarque ses propres références (7) + `proportion-capabilities.sh`.
- **`vf-calibrate`** — propagation d'update façon GSD : détecte l'écart framework ↔ lab
  (`framework-version.sh`), lit les changements de structure/doctrine, propose et pilote la
  migration **sous validation humaine**.
- **`vf-update`** — met à jour VibeFlow en deux couches sous confirmation : le plugin
  (`claude plugin update vibeflow@vibeflow-os`) puis les modules installés (engine `update --all`
  via `vf-update-run.sh`). Frontière : `vf-update` **installe** la nouvelle version,
  `vf-calibrate` **réaligne la structure** une fois celle-ci posée.

## Hooks (posés automatiquement à l'install)

`hooks/hooks.json` câble les gates dans la session :

- **PreToolUse(Write)** → `guard-agent-write.sh` : un agent non conforme ADR-044 ne peut pas être
  **écrit** dans `.claude/agents/` (deny avec erreurs précises + squelette canonique).
- **SessionStart** → `check-agents.sh --hook` (lint des agents posés), `check-debug-research.sh
  --hook` (advisory ADR-045 : recherche documentaire avant debug), `update-banner.sh` (bandeau
  « mise à jour disponible X → Y, lance /vf-update » + nudge de méthode legacy).

## Scripts (15) — par famille

**Gates machine (`check-*`)** :
- `check-agents.sh` — lint de conformité native des agents (ADR-044) : frontmatter, champs requis,
  skills déclarés existants, budget de préchargement, `vf-internal`, et depuis la Phase 16 le
  contenu du champ `tools:`/`disallowedTools:` (syntaxe des allowlists `Agent(...)`/`Task(...)`,
  noms d'outils, résolution graduée des noms d'agents avec préfixes tiers).
- `guard-agent-write.sh` — enforcement du gate ci-dessus à l'écriture (hook Write).
- `check-debug-research.sh` — phase de recherche documentaire avant debug dans les briques de
  dépannage (ADR-045).
- `check-legacy.sh` — détecte un lab resté sur l'ancienne méthode (pré ADR-052/053), scope-aware
  (racines user ET projet), verdicts `legacy` / `drift`.
- `check-overlaps.sh` — inventaire des recouvrements de déclenchement avec les briques tierces
  (ADR-057, advisory).
- `check-mission-invariants.sh` — gate advisory (Phase 20, D-15) : constate qu'un glob de zone de
  risque de `.planning/MISSION-INVARIANTS.md` ne matche plus aucun fichier suivi ; il ne juge
  jamais, il signale.
- `check-state-integrity.sh` — gate anti-régression (Phase 21) : `completed_phases`,
  `completed_plans`, `total_plans` et `current_phase` de `.planning/STATE.md` ne décroissent jamais
  au sein d'un même jalon, et le corps ne porte jamais plus d'une ligne `^Phase:` (ADR-063).

**Team-kernel** : `dag.sh` (plan de bataille persistant, frontière `ready`) et `driver-lock.sh`
(verrou de mission atomique par `mkdir`, heartbeat + TTL).

**Update** : `framework-version.sh` (current / recorded / stamp / drift, sémver portable),
`check-plugin-update.sh` (compare au dernier tag GitHub, cache local), `update-banner.sh` (hook
SessionStart), `vf-update-run.sh` (re-matérialise les modules depuis le cache plugin le plus récent).

**Scaffolding & incarnation** : `scaffold-docs.sh` (externalise la doc du lab sous `docs/`,
ADR-042) et `generate-agent-commands.sh` (une commande slash d'incarnation par agent posé — saute
les workers `vf-internal: true`, Pattern 12).

**Tests** : 12 suites sous `scripts/tests/` (une par script critique + `test-conductor.sh`,
`test-vf-new-lab.sh`, `test-vf-update.sh`, `test-doc-and-commands.sh`).

## Contenu du module

```
conductor/
  AGENT.md                         # vibeflow-conductor (méta orchestrateur + gardien)
  hooks/hooks.json                 # guard Write + lints SessionStart + bandeau update
  skills/
    vf-new-lab/                    # Lab Factory (SKILL.md + 7 references + script + test)
    vf-calibrate/SKILL.md          # propagation update + migration
    vf-update/SKILL.md             # mise à jour plugin + modules
  scripts/                         # 14 scripts (familles ci-dessus) + tests/ (12 suites)
  references/
    team-kernel.md                 # contrat du noyau d'équipe (manager/workers/juges)
    contracts.md                   # escalade sous-agents → conductor
    conductor-pipeline.md          # ordre canonique de configuration
    migration-playbook.md          # recettes de migration + wiring hook opt-in
    bootstrap-method.md            # méthode de cadrage + dérivation
```

## Limites

- **Jamais le travail métier** : le conductor configure et garde le lab, il ne produit pas ses
  livrables (l'orchestration métier vit dans les orchestrateurs métier, pas ici).
- **Jamais de correction/migration silencieuse** : détecter → proposer → validation humaine
  (ADR-031).
- Le kernel est fait pour les **missions**, pas le quotidien : sous le seuil d'équipe du métier,
  la brique outillée directe suffit.
