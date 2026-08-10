# mobile-test-team — La boucle autonome test → corrige → re-test

> Un mode autonome qui s'arrête aux tests unitaires ne prouve pas que **« l'app marche
> vraiment »**. Ce module ajoute la boucle manquante : trois agents cloisonnés qui testent
> l'app réelle sur cible mobile, corrigent, et re-testent jusqu'au vert — sans jamais tricher.

**Type** : agents + rules · **Version** : v1.4.3 · **Dépend de** : `mobile-test`

---

## Quoi

`vf-auto` enchaîne les phases et vérifie les gates **techniques** (lint, tsc, tests unitaires).
Sur mobile ça ne suffit pas : un écran peut compiler, passer ses tests, et crasher au runtime.
Ce module apporte :

1. **La boucle** — `vf-test-orchestrator` tient le cycle
   `[ vf-test-runner joue Maestro → rouge ? → vf-app-fixer corrige → re-test ]` avec baseline
   verte, anti-régression (revert), anti-thrash (abandon après N tentatives) et halt conditions.
2. **Le cloisonnement anti-triche (Pattern 12)** — celui qui corrige le code ne peut pas toucher
   aux tests, celui qui écrit les tests ne peut pas toucher au code. La séparation est portée par
   les `tools:` des agents, pas par de la prose : **aucun assert n'est jamais affaibli** pour
   « faire passer ».
3. **Une rule path-scopée** — `mobile-verify-gate.md` se charge toute seule dès qu'on édite du
   code d'écran mobile ou un flow Maestro, et rend active la doctrine « un critère observable à
   l'écran exige une vérif réelle » (extension mobile du Gate Nyquist, ADR-037).

```
execute (code + gates techniques verts)
  → vf-test-orchestrator :
      [ vf-test-runner → rouge ? → vf-app-fixer → re-test ]
      baseline verte · anti-régression · anti-thrash · halt conditions
  → phase done seulement si les critères observables sont vérifiés réellement
```

## Installation

Pré-requis modules (`module.json` → `requires`) : **`mobile-test`** — le pipeline mécanique que
la boucle pilote. L'install nue ne résout **pas** les dépendances : installe-les explicitement
dans l'ordre, ou passe `--with-deps`.

```bash
.claude/scripts/vibeflow-update.sh install mobile-test
.claude/scripts/vibeflow-update.sh install mobile-test-team
# ou en un coup :
.claude/scripts/vibeflow-update.sh install --with-deps mobile-test-team
```

Pré-requis **système** : ceux de `mobile-test` (Node, Maestro + JDK, Xcode/`simctl` ou `adb` +
émulateur, projet Expo/RN, config `.vibeflow/mobile-test.json` posée). Le MCP du lab (ex.
`mobile-mcp`) est injecté dans l'allowlist des 3 agents à l'install via `vf-mcp-consumer: true`
(ADR-051) — aucun serveur en dur.

⚠️ **Redémarre Claude Code après (ré)install** : le `tools:` des agents est lu au démarrage de
session.

**Modèle d'activation** : conçu pour un install global (scope `user`), dormant hors mobile —
la rule est path-scopée sur des marqueurs discriminants, le script lit sa config par projet, et
l'orchestrateur **décline** si le projet n'est pas mobile (garde `app.json`/Expo).

## Démarrer

Sur un projet Expo/RN avec la config `mobile-test` posée et une phase dont les critères sont
observables à l'écran, dis :

> « Fais passer cette phase au vert sur le simulateur »

(ou laisse `vf-auto` dispatcher l'orchestrateur en fin d'exécution d'une phase mobile). Ce qui
se passe :

1. **Garde** — l'orchestrateur vérifie les marqueurs mobile ; projet non mobile → il décline.
2. **Couverture + premier run** — `vf-test-runner` mappe les critères aux flows Maestro, écrit
   les flows manquants, joue le pipeline `mobile-test` (détection cible, build-if-missing,
   régression).
3. **Baseline** — l'ensemble des flows verts + le SHA git sont mémorisés (anti-régression).
4. **Boucle de fix** — pour chaque flow rouge, `vf-app-fixer` reçoit l'échec + son diagnostic
   et corrige le code app (un fix = un commit atomique), puis re-test complet.
5. **Rapport** — verdict global (vert / partiel / bloqué), diff, commits, abandons, terminé par
   le **bloc typé** ADR-053 (`{statut, findings[], noeuds_debloques}`) pour le contrôle de flux
   de `vf-dev-manager`.

## Usage

- **Nuit / autonomie** : la boucle est faite pour tourner sans supervision (dispatchée par
  `vf-auto` sur un projet mobile). Budgets optionnels dans un `night-run.json` à la racine :
  `maxWallClockMinutes`, `maxTokens`, `maxAttemptsPerFlow` (défaut 3), `maxResearchRoundsPerFlow`
  (défaut 2), `revertOnRegression` (défaut true).
- **Recherche documentaire avant fix intensif (ADR-045)** : sur un flow déjà tenté, un échec
  lib/framework/natif/version, ou un `doc-research-required` remonté par le fixer (cloisonné sans
  web), l'orchestrateur **porte lui-même** la recherche (context7 + WebSearch : issues GitHub,
  release notes) puis redispatche avec des pistes sourcées — pas de fix aveugle, 1 seul saut.
- **Options de projet lues, jamais présumées** : politique de push (repo client → local
  seulement) et attribution des commits (pas de mention d'IA si le projet l'exige) viennent du
  `CLAUDE.md`/rules du projet cible.
- **Arrêt** : tout vert, plafond temps/tokens, ou tous les flows restants abandonnés — plus les
  halt conditions dures (HALT-2 sans progrès, HALT-3 action destructive, HALT-4 ressource ou
  info manquante, HALT-5 drift de scope).

## Référence

### Agents (cloisonnement par `tools:`, Pattern 12)

| Agent | Rôle | `tools:` (le couloir) | Interne |
|-------|------|----------------------|:---:|
| `vf-test-orchestrator` | tient la boucle, applique garde-fous et halts, porte la recherche doc (ADR-045), rapport typé ADR-053 | Read, Write, Bash, Glob, Grep, **WebSearch, WebFetch**, `Agent(vf-test-runner, vf-app-fixer)` — ne peut spawner **que** ses 2 workers | non |
| `vf-test-runner` | possède les tests : écrit les flows manquants (**jamais affaiblir un assert**), joue le pipeline, diagnostic structuré | Read, Edit, Write, Bash, Glob, Grep — écrit **uniquement** dans `maestroFlowsDir` ; pas de `Task`, pas de web | `vf-internal: true` |
| `vf-app-fixer` | corrige **uniquement** le code app, un fix = un commit atomique ; remonte `doc-research-required` plutôt que bricoler | Read, Edit, Write, Bash, Glob, Grep — interdit d'écrire dans les tests ; pas de `Task`, pas de web | `vf-internal: true` |

Les 3 agents : `model: sonnet`, `memory: project`, `vf-mcp-consumer: true` (allowlist MCP dérivée
du lab). Les workers `vf-internal` n'ont pas de commande d'incarnation (Pattern 12 / ADR-044) —
seuls l'orchestrateur les dispatche.

### Rules et références

| Fichier | Rôle |
|---------|------|
| `rules/mobile-verify-gate.md` | rule **path-scopée** sur des marqueurs discriminants mobile (`app/**/_layout.tsx`, `src/screens/**`, `.maestro/**`) — dormante sur un projet web ; rend la doctrine de vérification réelle active pendant le dev |
| `references/test-loop-protocol.md` | protocole de la boucle (invariants, budgets) + mapping halt conditions Pattern 11, insertion dans le flux `god-execution`/`vf-auto` — chargé on-demand |

## Limites

- ⚠️ **Statut expérimental.** Le point le plus risqué — un sous-agent
  (`vf-test-orchestrator`) qui spawne d'autres sous-agents via `Task` **et** invoque le pipeline —
  n'a **pas encore été prouvé par un run réel vert de bout en bout** dans un contexte VibeFlow.
  La condition de sortie du statut est ce run : une phase mobile pilotée sans intervention, avec
  au moins un cycle de fix et un arrêt propre. Tant qu'il n'existe pas, considère le module comme
  une base solide **à confirmer**.
- **Allowlist ≠ barrière dure** : Claude Code n'a pas de champ « agent interne seulement » — les
  workers restent techniquement auto-délégables. La parade est l'allowlist `Agent(...)` côté
  orchestrateur + `vf-internal` + descriptions dissuasives : heuristique robuste, pas un mur.
- **Mobile uniquement** (Expo/React Native) : l'orchestrateur décline ailleurs ; la rule reste
  dormante hors marqueurs mobile.
- **Redémarrage requis** après (ré)install pour que les `tools:` (dont l'injection MCP) soient
  pris en compte.
- Doctrine des garde-fous : `dev-orchestrator/references/autonomous-guardrails.md` ·
  Patterns 09 (god-execution), 11 (halt), 12 (cloisonnement) : module `reference` ·
  Pipeline mécanique : module `mobile-test` (skill `vf-mobile-test`).
