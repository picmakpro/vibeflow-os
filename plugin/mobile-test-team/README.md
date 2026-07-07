# mobile-test-team — Équipe de test mobile autonome

> Module VibeFlow qui ajoute **la boucle test → corrige → re-test** manquante : celle qui fait
> qu'un mode autonome (`vf-auto`) ne s'arrête plus aux tests unitaires, mais va jusqu'à **« l'app
> marche vraiment »** sur simulateur/émulateur. Trois agents cloisonnés + une **rule path-scopée**
> qui invoque la doctrine de vérification réelle **automatiquement** dès qu'on développe du mobile.

**Version** : v1.0.0
**Type** : agents + rules
**Requires** : `mobile-test` (le pipeline mécanique qu'elle pilote)
**Statut** : ⚠️ **expérimental** — l'orchestration de sous-agents imbriqués doit être prouvée par un
run réel de bout en bout (voir § Statut).

---

## Le problème qu'il résout

`vf-auto` enchaîne déjà les phases (cadrage → plan → exécution → *done* → suivante) et vérifie les
**gates techniques** (lint, tsc, tests unitaires). Mais sur mobile, ça ne suffit pas : **un écran
peut compiler, passer ses tests unitaires, et crasher au runtime.** Il manquait l'étape « teste
l'app réelle et corrige en boucle jusqu'au vert ». C'est ce module.

## Ce qu'il apporte

### 1. Trois agents cloisonnés (Pattern 12)

| Agent | Rôle | Écrit | Escalade (`Task`) |
|-------|------|-------|:---:|
| `vf-test-orchestrator` | Tient la boucle, dispatche les workers, applique les garde-fous et halt conditions | rapport | ✅ |
| `vf-test-runner` | Possède les tests : écrit la couverture manquante, joue le pipeline | **tests seuls** | ❌ |
| `vf-app-fixer` | Corrige **uniquement** le code app, commit atomique | **code seul** | ❌ |

Le cloisonnement au niveau `tools:` **rend la triche impossible** : le correcteur de code ne peut
pas toucher aux tests, l'auteur des tests ne peut pas toucher au code. Aucun assert n'est jamais
affaibli pour « faire passer ».

### 2. Une rule qui invoque la doctrine **naturellement**

`rules/mobile-verify-gate.md` est **path-scopée** : elle se charge toute seule dès qu'on édite du
code d'écran mobile ou un flow de test — sans invocation manuelle. Elle rappelle, au bon moment,
que **un critère observable à l'écran exige une vérif réelle (Maestro)**, pas seulement un test
unitaire (extension mobile du Gate Nyquist, ADR-037), et pointe vers la boucle test+fix.

C'est le mécanisme qui transforme la doctrine de documentation passive en **règle active pendant
le dev** — le même patron que `feature-dev-gates`.

## La boucle (résumé)

```
execute (code + gates techniques verts)
  → vf-test-orchestrator :
      [ vf-test-runner joue Maestro sur la cible → rouge ? → vf-app-fixer corrige → re-test ]
      baseline verte · anti-régression (revert) · anti-thrash (abandon après 3) · halt conditions
  → phase done seulement si les critères observables sont vérifiés réellement
```

## Structure

```
mobile-test-team/
├── module.json                       # requires: [mobile-test]
├── agents/
│   ├── vf-test-orchestrator.md       # la boucle
│   ├── vf-test-runner.md             # tests (cloisonné)
│   └── vf-app-fixer.md               # code (cloisonné)
├── rules/
│   └── mobile-verify-gate.md         # rule path-scopée = invocation naturelle de la doctrine
└── references/
    └── test-loop-protocol.md         # protocole + mapping halt conditions (on-demand)
```

## Modèle d'installation : global une fois, actif dans les bons projets

Ce module (comme `mobile-test`) est conçu pour être **installé une seule fois en scope `user`**
(`~/.claude/`) et **ne s'activer que dans les projets mobiles** — dormant partout ailleurs. Le
mécanisme repose sur des comportements **natifs** de Claude Code :

| Artefact | Où (scope user) | Activation |
|----------|-----------------|------------|
| `rules/mobile-verify-gate.md` | `~/.claude/rules/` | **Path-scopée** : le `paths:` est évalué relativement au **projet courant**. Se charge seulement si le projet touche `app/**/*.tsx`, `.maestro/**`, etc. Dormante sur un projet non-mobile. |
| Script `mobile-test-run.mjs` | `~/.claude/scripts/` | Lit sa config **par projet** (`./.vibeflow/mobile-test.json`). Sans config projet → n'agit pas. |
| Agents `vf-test-*`, `vf-app-fixer` | `~/.claude/agents/` | Pas de path-scoping natif ; l'orchestrateur **décline si le projet n'est pas mobile** (garde `app.json`/Expo). Les workers ne sont dispatchés que par l'orchestrateur. |

**En clair** : l'utilisateur installe VibeFlow + le module dev en global, et l'outillage mobile
s'invoque **tout seul** dès qu'il code une app mobile (via la rule path-scopée), sans jamais
apparaître comme du bruit sur ses projets web ou backend. Pour activer le pipeline sur un projet
donné, il suffit d'y poser un `.vibeflow/mobile-test.json` (copié du template de `mobile-test`).

## Config

Réutilise la config du module `mobile-test` (`.vibeflow/mobile-test.json`) et, optionnellement, un
`night-run.json` à la racine du projet : `maxWallClockMinutes`, `maxTokens`, `maxAttemptsPerFlow`
(défaut 3), `revertOnRegression` (défaut true).

## Statut

**Expérimental.** Le point le plus risqué — un sous-agent (`vf-test-orchestrator`) qui **spawne
d'autres sous-agents** (`vf-test-runner`, `vf-app-fixer`) via `Task` **et** invoque le pipeline —
doit être prouvé par un **run réel de bout en bout** dans l'environnement VibeFlow (une phase mobile
pilotée sans intervention, avec au moins un cycle de fix et un arrêt propre). Tant que ce run
n'existe pas, considère le module comme une base solide mais à confirmer.

## Références

- Pipeline mécanique : module `mobile-test` (skill `vf-mobile-test`).
- Doctrine des garde-fous : `dev-orchestrator/references/autonomous-guardrails.md`.
- Patterns 09 (god-execution), 11 (halt), 12 (cloisonnement) : module `reference`.
- Cadrage : `.planning/research/brique5-orchestration-CADRAGE.md`.
