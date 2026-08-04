# GSD Capabilities Index (auto-généré — NE PAS ÉDITER)
> Généré le 2026-08-04T20:50:52+02:00 par build-gsd-capabilities-index.sh
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
| `external-job` | contribution | `external_job.enabled` | — | `skip` |
| `mempalace` | contribution | `mempalace.enabled` | — | `skip` |
| `drift` | gate | `workflow.schema_drift_gate` | oui | `skip` |
| `drift` | gate | `workflow.schema_drift_gate` | non | `skip` |
| `ui` | gate | `workflow.ui_safety_gate` | oui | `halt` |

## `execute:post`

| Capability | Nature | Toggle gouvernant | Bloquant | Conduite sur erreur |
|---|---|---|---|---|
| `code-review` | step | `workflow.code_review` | — | `skip` |
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
| `antigravity` | runtime | `review.models.agy` |
| `audit` | feature | — |
| `augment` | runtime | — |
| `claude` | runtime | `review.models.claude` |
| `cline` | runtime | — |
| `codebuddy` | runtime | — |
| `coderabbit` | reviewer | — |
| `codex` | runtime | `review.models.codex` |
| `copilot` | runtime | — |
| `cursor` | runtime | — |
| `gemini` | reviewer | `review.models.gemini` |
| `graphify` | feature | `graphify.enabled` |
| `hermes` | runtime | — |
| `kilo` | runtime | — |
| `kimi` | runtime | — |
| `kimi-code` | runtime | `review.models.kimi-code` |
| `llama-cpp` | reviewer | — |
| `lm-studio` | reviewer | — |
| `ollama` | reviewer | — |
| `opencode` | runtime | `review.models.opencode` |
| `pi` | runtime | — |
| `profile-pipeline` | feature | `profile-pipeline.enabled` |
| `qwen` | runtime | — |
| `trae` | runtime | — |
| `vscode` | runtime | — |
| `windsurf` | runtime | — |
| `zcode` | runtime | — |

---

> 12 point(s) de hook parcouru(s), 35 étage(s) déclaré(s) par le registre, 27 capability(ies) hors point de hook sur 44 déclarée(s).
