# Changelog — mobile-test-team

## v1.0.1 — 2026-07-07

### Corrigé
- `vf-test-runner` et `vf-app-fixer` marqués **`vf-internal: true`** : ces workers ne reçoivent plus
  de commande d'incarnation `/vf-test-runner` / `/vf-app-fixer` lors du sweep `vf-new-lab`. Ils
  restent dispatchés uniquement par `vf-test-orchestrator` (cohérent avec l'allowlist `Agent(...)`
  et leur description). L'orchestrateur, lui, reste invocable en direct. Requiert conductor v1.7.0.

## v1.0.0 — 2026-07-07

Création du module (brique 5b + 5c). Équipe de test mobile autonome, extraite et généralisée
depuis le track « équipe d'agents » (revizapp), câblée sur la doctrine VibeFlow existante.

- **3 agents cloisonnés** (Pattern 12) : `vf-test-orchestrator` (boucle + garde-fous + halt),
  `vf-test-runner` (tests seuls, pas de `Task`), `vf-app-fixer` (code seul, pas de `Task`).
- **Rule path-scopée** `mobile-verify-gate.md` : invoque la doctrine de vérification réelle
  **automatiquement** dès qu'on touche du code mobile (extension mobile du Gate Nyquist, ADR-037).
  Répond au besoin « la doctrine doit être invoquée naturellement lors du dev ».
- **Référence** `test-loop-protocol.md` : protocole de boucle + mapping halt conditions, insertion
  dans le flux `god-execution`/`vf-auto`.

### Généralisation vs source revizapp

- Retrait des constantes projet (bundle id, i18n, THEME, dossiers `.agent/`/`docs/_mission/`).
- « jamais de push » et « pas de mention d'IA dans les commits » → **options de projet** lues dans
  le `CLAUDE.md`/rules du projet cible, plus des constantes.
- Préfixe `vf-`, descriptions FR, invocables utilisateur ET agent.

### Dépendance engine

Nécessite le support **multi-agents** de l'installeur (`agents/*.md` → `.claude/agents/<name>.md`),
ajouté à `_internal/vibeflow-update.sh` dans la même livraison.

### Modèle d'installation (validé via doc Claude Code officielle)

Conçu pour un **install global (scope user)** avec **activation par projet** : la rule est
path-scopée (évaluée sur le projet courant → dormante hors mobile), le script lit sa config par
projet, et l'orchestrateur décline si le projet n'est pas mobile. Documenté dans le README.

### Cloisonnement des workers (allowlist)

`vf-test-orchestrator` déclare `tools: …, Agent(vf-test-runner, vf-app-fixer)` : il ne peut spawner
**que** ces deux workers (Pattern 12, règle 5). **Limite connue** : Claude Code n'offre pas de champ
« agent interne seulement » — les workers restent techniquement auto-délégables ; la parade est
l'allowlist côté orchestrateur + leurs descriptions dissuasives. Heuristique robuste, pas barrière dure.

### Statut

Expérimental jusqu'au premier run réel vert (nesting de sous-agents à prouver en conditions réelles).
