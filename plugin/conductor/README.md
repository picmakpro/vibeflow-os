# conductor

> **L'orchestrateur méta et gardien du lab.** La porte d'entrée pour tout ce qui touche la
> *configuration* du lab — créer, installer, vérifier, mettre à jour, migrer — dans **n'importe quel
> métier**. Pas appelé en continu : il intervient aux moments de config, d'audit et de migration.

**Type** : `agent + skills + scripts + references` · **Version** : v1.14.1 · **Dépend de** : `planning-core`, `validator`.

---

## Pourquoi ce module

Audit du plugin (juin 2026) : il savait **installer des briques** de façon agnostique, mais pas
**construire un lab à partir d'un métier**, ni se comporter en **framework vivant**. `conductor` comble
4 trous :

| # | Trou comblé | Brique |
|---|---|---|
| **C1** | Pas d'agent méta central | Agent `vibeflow-conductor` |
| **C2** | Pas de bootstrap de lab universel (`vf-init` était dev-couplé) | Skill `vf-new-lab` |
| **C3** | Pas de propagation/migration d'update façon GSD | Skill `vf-calibrate` + `framework-version.sh` |
| **C4** | Pas d'escalade sous-agents → gardien | `references/contracts.md` |

## L'agent `vibeflow-conductor` — 4 rôles

1. **Configurateur** — crée un lab depuis ton métier (`vf-new-lab`), pose les modules, le planning.
2. **Vérificateur** — déclenche l'audit complet (`vibeflow-validator`, 5 phases).
3. **Calibreur** — détecte qu'une évolution du framework impacte le lab et pilote la migration.
4. **Gardien** — reçoit les escalades de cohérence des sous-agents, arbitre, route.

Il **route et délègue** — ne réimplémente jamais, ne fait jamais le travail métier.

## Créer un lab dans n'importe quel métier (install chirurgicale)

Parle au conductor : *« crée un lab d'acquisition »*. Il pose **5 questions que tu sais déjà**
(métier, process/livrables, objectif, contraintes, vocabulaire), puis **dérive** le lab : `CLAUDE.md`
métier + `.planning/` adapté + registres mémoire + 2-3 agents métier + auditeurs câblés. **Zéro
hypothèse dev** — un lab d'acquisition obtient une extension `acquisition/`, pas un `codebase/`.

## Voir et absorber les mises à jour (façon GSD)

`framework-version.sh` enregistre la version du framework dans le lab et détecte quand il « prend du
retard ». Un hook SessionStart **opt-in** (jamais imposé) surface *« le framework a bougé, lance
/vf-calibrate »*. La migration se fait **sous validation humaine** (ADR-031) : détecter → proposer →
valider → appliquer → re-auditer. C'est aussi l'outil par lequel l'équipe VibeFlow recalibre un lab
branché selon la dernière version.

## Contenu du module

```
conductor/
  AGENT.md                       # vibeflow-conductor (méta orchestrateur + gardien)
  skills/
    vf-new-lab/SKILL.md          # C2 — bootstrap de lab universel
    vf-calibrate/SKILL.md        # C3 — propagation update + migration
  scripts/
    framework-version.sh         # current / recorded / stamp / drift (sémver portable)
    tests/test-conductor.sh
  references/
    contracts.md                 # C4 — escalade sous-agents → conductor
    conductor-pipeline.md        # ordre canonique de configuration
    migration-playbook.md        # recettes de migration + wiring hook opt-in
    bootstrap-method.md          # méthode de cadrage + dérivation (5 questions)
```
