# GSD Capabilities Index (auto-généré — NE PAS ÉDITER)
> Généré le 2026-08-31T14:48:50+02:00 par build-gsd-capabilities-index.sh
> Source : registre de capabilities du moteur GSD (`capability-registry.cjs`), schéma déclaré `1`

**Ce que cette table dit.** Elle énumère ce que le moteur **déclare** à la version depuis
laquelle elle a été générée : quels étages *peuvent* se déclencher à chaque point de hook du
cycle, et sous quel toggle. Le moteur insère ces étages lui-même — un agent ne les choisit pas.

**Ce que cette table ne dit pas.** Elle ne dit **jamais** ce qui est effectivement actif sur un
lab donné. La colonne « toggle gouvernant » nomme la condition ; elle ne la résout pas. Pour
l'état effectif d'un lab, la commande est `gsd-tools loop render-hooks <point> --raw`, pas ce
fichier.

## `discuss:pre`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `mempalace` | contribution | `mempalace.enabled` | — | `skip` |

## `discuss:post`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `mempalace` | step | `mempalace.enabled` | — | `skip` |

## `plan:pre`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `ai-integration` | step | `workflow.ai_integration_phase` | — | `skip` |
| `intel` | step | `intel.enabled` | — | `skip` |
| `mempalace` | step | `mempalace.enabled` | — | `skip` |
| `research` | step | `workflow.research` | — | `skip` |
| `ui` | step | `workflow.ui_phase` | — | `skip` |
| `pattern-mapper` | step | `workflow.pattern_mapper` | — | `skip` |
| `ai-integration` | contribution | `workflow.api_coverage_gate` | — | `skip` |
| `assumption-delta` | contribution | `workflow.assumption_delta` | — | `skip` |
| `schema-gate` | contribution | `workflow.schema_push_detection` | — | `skip` |
| `security` | contribution | `workflow.security_enforcement` | — | — |
| `tdd` | contribution | `workflow.tdd_mode` | — | `skip` |
| `drift` | gate | `workflow.plan_drift_precheck` | non | `skip` |
| `ui` | gate | `workflow.ui_safety_gate` | oui | `halt` |

## `plan:post`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `mempalace` | step | `mempalace.enabled` | — | `skip` |
| `claude-orchestration` | contribution | `claude_orchestration.enabled` | — | `skip` |
| `external-job` | contribution | `external_job.enabled` | — | `skip` |
| `gap-analysis` | gate | `workflow.post_planning_gaps` | non | `skip` |

## `execute:pre`

_Aucun étage déclaré à ce point par le registre du moteur — l'information est que le
point existe et reste vide, pas qu'il est absent._

## `execute:wave:pre`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `claude-orchestration` | contribution | `claude_orchestration.enabled` | — | `skip` |

## `execute:wave:post`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `live-dom-uat` | step | `workflow.live_dom_uat` | — | `skip` |
| `external-job` | contribution | `external_job.enabled` | — | `skip` |
| `mempalace` | contribution | `mempalace.enabled` | — | `skip` |
| `drift` | gate | `workflow.schema_drift_gate` | oui | `skip` |
| `drift` | gate | `workflow.schema_drift_gate` | non | `skip` |
| `ui` | gate | `workflow.ui_safety_gate` | oui | `halt` |

## `execute:post`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `code-review` | step | `workflow.code_review` | — | `skip` |
| `refactor-trigger` | step | `refactor.trigger_enabled` | — | `skip` |
| `tdd` | gate | `workflow.tdd_mode` | non | `skip` |

## `verify:pre`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `ai-integration` | gate | `workflow.api_coverage_gate` | oui | `halt` |

## `verify:post`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `mempalace` | step | `mempalace.enabled` | — | `skip` |
| `nyquist` | step | `workflow.nyquist_validation` | — | `halt` |
| `security` | step | `workflow.security_enforcement` | — | `halt` |
| `ui` | step | `workflow.ui_review` | — | `skip` |

## `ship:pre`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `broken-windows` | gate | `workflow.windows_enforce` | oui | `halt` |
| `security` | gate | `workflow.security_enforcement` | oui | `halt` |

## `ship:post`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `mempalace` | step | `mempalace.enabled` | — | `skip` |

## Capabilities hors point de hook

Ces capabilities sont **déclarées par le registre** mais n'apparaissent à aucun point de
hook — le moteur ne les insère donc jamais dans le cycle. Lire la colonne `Rôle` avant de
conclure : pour un `runtime` ou un `reviewer`, n'avoir aucun étage est l'état **normal** ;
c'est seulement pour une `feature` que cela signale une capacité **dormante**.

La clé gouvernante vient de `activationKey` quand le registre en déclare une, sinon de
l'unique clé du bloc `config` de la capability. `—` signifie que le registre n'en déclare
aucune — jamais qu'elle est introuvable.

| Capability | Rôle | Clé de configuration gouvernante |
|---|---|---|
| `antigravity` | runtime | — |
| `audit` | feature | — |
| `augment` | runtime | — |
| `claude` | runtime | — |
| `cline` | runtime | — |
| `codebuddy` | runtime | — |
| `coderabbit` | reviewer | — |
| `codex` | runtime | — |
| `copilot` | runtime | — |
| `cursor` | runtime | — |
| `gemini` | reviewer | — |
| `graphify` | feature | `graphify.enabled` |
| `hermes` | runtime | — |
| `kilo` | runtime | — |
| `kimi` | runtime | — |
| `kimi-code` | runtime | — |
| `llama-cpp` | reviewer | — |
| `lm-studio` | reviewer | — |
| `ollama` | reviewer | — |
| `opencode` | runtime | — |
| `pi` | runtime | — |
| `profile-pipeline` | feature | `profile-pipeline.enabled` |
| `qwen` | runtime | — |
| `trae` | runtime | — |
| `vscode` | runtime | — |
| `windsurf` | runtime | — |
| `zcode` | runtime | — |

## Toggles gouvernants déclarés par le registre

Type et **défaut amont** de **chaque toggle nommé ailleurs dans ce document** — condition
`when` d'un étage comme clé gouvernante d'une capability. Les deux colonnes sont lues dans
`configSchema`, jamais inférées. `Défaut` est la valeur qui s'applique quand la clé est
**absente** du `.planning/config.json` d'un lab : une clé absente n'est PAS synonyme
d'inactive, et `—` en colonne `Type` signale un toggle que le registre ne décrit pas.

| Toggle gouvernant | Propriétaire | Type | Défaut amont |
|---|---|---|---|
| `mempalace.enabled` | `mempalace` | boolean | non |
| `workflow.ai_integration_phase` | `ai-integration` | boolean | oui |
| `intel.enabled` | `intel` | boolean | non |
| `workflow.research` | `research` | boolean | oui |
| `workflow.ui_phase` | `ui` | boolean | oui |
| `workflow.pattern_mapper` | `pattern-mapper` | boolean | oui |
| `workflow.api_coverage_gate` | `ai-integration` | boolean | oui |
| `workflow.assumption_delta` | `assumption-delta` | boolean | oui |
| `workflow.schema_push_detection` | `schema-gate` | boolean | oui |
| `workflow.security_enforcement` | `security` | boolean | oui |
| `workflow.tdd_mode` | `tdd` | boolean | non |
| `workflow.plan_drift_precheck` | `drift` | boolean | oui |
| `workflow.ui_safety_gate` | `ui` | boolean | oui |
| `claude_orchestration.enabled` | `claude-orchestration` | boolean | non |
| `external_job.enabled` | `external-job` | boolean | non |
| `workflow.post_planning_gaps` | `gap-analysis` | boolean | oui |
| `workflow.live_dom_uat` | `live-dom-uat` | boolean | non |
| `workflow.schema_drift_gate` | `drift` | boolean | oui |
| `workflow.code_review` | `code-review` | boolean | oui |
| `refactor.trigger_enabled` | `refactor-trigger` | boolean | non |
| `workflow.nyquist_validation` | `nyquist` | boolean | oui |
| `workflow.ui_review` | `ui` | boolean | oui |
| `workflow.windows_enforce` | `broken-windows` | boolean | non |
| `graphify.enabled` | `graphify` | boolean | non |
| `profile-pipeline.enabled` | `profile-pipeline` | boolean | non |

## Briques routées et leur toggle gouvernant

Chaque brique que le moteur rattache à une capability, et le toggle qui la rend inerte.
`bySkill` fournit les skills (clés nues, préfixées `gsd-` ici — **seule** transformation de
ce document), `byAgent` les agents (clés déjà complètes, reprises telles quelles). Une
entrée de documentation qui promet une de ces briques promet un geste que son toggle peut
rendre inerte : c'est exactement ce que `check-capability-activation.sh` confronte.

| Brique | Capability | Toggle gouvernant |
|---|---|---|
| `gsd-ai-integration-phase` | `ai-integration` | — |
| `gsd-code-review` | `code-review` | — |
| `gsd-graphify` | `graphify` | `graphify.enabled` |
| `gsd-mempalace-recall` | `mempalace` | `mempalace.enabled` |
| `gsd-mempalace-capture` | `mempalace` | `mempalace.enabled` |
| `gsd-validate-phase` | `nyquist` | `workflow.nyquist_validation` |
| `gsd-profile-user` | `profile-pipeline` | `profile-pipeline.enabled` |
| `gsd-secure-phase` | `security` | — |
| `gsd-ui-phase` | `ui` | — |
| `gsd-ui-review` | `ui` | — |
| `gsd-framework-selector` | `ai-integration` | — |
| `gsd-ai-researcher` | `ai-integration` | — |
| `gsd-domain-researcher` | `ai-integration` | — |
| `gsd-eval-planner` | `ai-integration` | — |
| `gsd-code-reviewer` | `code-review` | — |
| `gsd-code-fixer` | `code-review` | — |
| `gsd-dom-verifier` | `live-dom-uat` | `workflow.live_dom_uat` |
| `gsd-mempalace-curator` | `mempalace` | `mempalace.enabled` |
| `gsd-nyquist-auditor` | `nyquist` | `workflow.nyquist_validation` |
| `gsd-pattern-mapper` | `pattern-mapper` | `workflow.pattern_mapper` |
| `gsd-user-profiler` | `profile-pipeline` | `profile-pipeline.enabled` |
| `gsd-phase-researcher` | `research` | `workflow.research` |
| `gsd-security-auditor` | `security` | — |
| `gsd-ui-checker` | `ui` | — |
| `gsd-ui-auditor` | `ui` | — |

---

> 12 point(s) de hook parcouru(s), 37 étage(s) déclaré(s) par le registre, 27 capability(ies) hors point de hook sur 46 déclarée(s), 25 toggle(s) gouvernant(s) distinct(s), 25 brique(s) routée(s).
