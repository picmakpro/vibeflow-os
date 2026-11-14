# A6 — Surface officielle de Claude Code pour un tableau de bord de sessions

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. Rapport brut de l'agent de documentation (pages officielles lues le 2026-11-10 ; quatre points non confirmés, dits en tête). Rendu le 2026-11-10 sur `release/v2.77.0` (cockpit v1.4.0 et retours du panel non publiés). Texte de l'agent, chemins ramenés à la racine du dépôt. Les identifiants de suivi (`AUDC-…`) et la destination de chaque constat sont dans `REGISTRE.md`.

---

## Réponse : sources officielles pour un tableau de bord de sessions Claude Code

Les pages ont été lues directement (la carte de docs était tronquée). Quatre points ne sont pas confirmés : les champs `Notification` (`message`, `title`, `notification_type`) et `SubagentStart` ont été lus sur des extraits partiels ; je n'ai pas trouvé de fichier d'état documenté pour Remote Control ; le schéma des lignes JSONL n'est pas documenté.

### 1. Hooks

**Liste** : la référence annonce 33 événements : `SessionStart`, `Setup`, `UserPromptSubmit`, `UserPromptExpansion`, `PreToolUse`, `PermissionRequest`, `PermissionDenied`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `Notification`, `MessageDisplay`, `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `Stop`, `StopFailure`, `TeammateIdle`, `InstructionsLoaded`, `ConfigChange`, `CwdChanged`, `DirectoryAdded`, `FileChanged`, `WorktreeCreate`, `WorktreeRemove`, `PreCompact`, `PostCompact`, `PreModelSwitch`, `PostModelSwitch`, `Elicitation`, `ElicitationResult`, `SessionEnd`. Source : https://code.claude.com/docs/en/hooks.md

**Champs communs** (stdin) : `session_id`, `transcript_path`, `cwd`, `hook_event_name`, `permission_mode`, `prompt_id`, `effort`, `agent_id` et `agent_type` (dans un subagent, teammate ou avec `--agent`).

**Champs par événement** :
- `SessionStart` : `source` (`startup`, `resume`, `clear`, `compact`, `fork`), `model` (optionnel).
- `UserPromptSubmit` : `prompt`.
- `PreToolUse` / `PostToolUse` : `tool_name`, `tool_input`, `tool_use_id` ; `PostToolUse` ajoute `tool_response` (schéma dépendant de l'outil) et `duration_ms`.
- `PermissionRequest` : `tool_name`, `tool_input`, `permission_suggestions`, `mcp_server` ; pas de `tool_use_id`.
- `Notification` : `message`, `title`, `notification_type`.
- `SubagentStart` : `agent_id`, `agent_type`.
- `SubagentStop` : `agent_id`, `agent_type`, `agent_transcript_path` (transcript propre du subagent), `last_assistant_message`, `stop_hook_active`.
- `Stop` : `last_assistant_message`, `stop_hook_active`, `background_tasks`, `session_crons`.
- `SessionEnd` : `reason` (`clear`, `resume`, …).

**Attente humaine** :
- `Notification` avec un matcher sur `notification_type` : `permission_prompt`, `idle_prompt`, `elicitation_dialog`, `elicitation_url_dialog`, `agent_needs_input`, `agent_completed`, etc.
- `PermissionRequest` se déclenche quand une décision de permission est nécessaire. C'est le signal le plus précis pour « attend une permission ».
- Une question posée via l'outil `AskUserQuestion` passe par `PreToolUse` : c'est une déduction, la page ne le dit pas explicitement.
- Le signal de fin d'attente n'est pas documenté. Il faut le déduire de `PostToolUse` ou `PermissionDenied`.

**Transport** : les hooks de type `http` reçoivent le même JSON en corps POST. Un tableau de bord local peut donc recevoir les événements directement, sans script intermédiaire.

**Stabilité** : les hooks `command` et `http` sont documentés. La page précise que les hooks de type agent sont expérimentaux.

### 2. OpenTelemetry

Source : https://code.claude.com/docs/en/monitoring-usage.md

**Activation** : `CLAUDE_CODE_ENABLE_TELEMETRY=1`, puis `OTEL_METRICS_EXPORTER` (`otlp`, `prometheus`, `console`, `none`), `OTEL_LOGS_EXPORTER` (`otlp`, `console`, `none`), `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`. Les événements requièrent l'exporteur de logs.

**Métriques** : `claude_code.session.count`, `claude_code.cost.usage` (USD), `claude_code.token.usage` (attribut `model`), `claude_code.active_time.total` (s), `claude_code.lines_of_code.count`, `claude_code.commit.count`, `claude_code.pull_request.count`, `claude_code.code_edit_tool.decision`.

**Événements** : `claude_code.user_prompt`, `claude_code.tool_result`, `claude_code.tool_decision` (décisions de permission), `claude_code.api_request`, `claude_code.api_error`, `claude_code.api_refusal`, `claude_code.assistant_response`. La liste est tronquée dans ma lecture.

**Attributs** : `session.id` (activé par défaut), `app.version`, `app.entrypoint`, `user.id`, `terminal.type`, `organization.id`.

**Exports** : console oui ; prometheus en pull (`localhost:9464/metrics`) ; **pas d'exporteur fichier OTel documenté**. Une sortie disque existe hors OTel : `OTEL_LOG_RAW_API_BODIES=file:<dir>` écrit les corps d'API avec un `index.jsonl`.

**Stabilité** : documentée.

### 3. Status line

Source : https://code.claude.com/docs/en/statusline.md

Le script reçoit du JSON sur stdin. Champs documentés :
- **Session** : `session_id`, `transcript_path`, `version`, `output_style.name`, `agent.name` (avec `--agent`), `effort.level`, `vim.mode`.
- **Modèle** : `model.id`, `model.display_name`.
- **Coût** : `cost.total_cost_usd` (estimation au tarif catalogue, sauf `modelPricing`), `cost.total_duration_ms`, `cost.total_api_duration_ms`, `cost.total_lines_added`, `cost.total_lines_removed`.
- **Contexte** : `context_window.total_input_tokens`, `total_output_tokens`, `context_window_size`, `used_percentage`, `remaining_percentage`, `current_usage` (`input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`), `exceeds_200k_tokens`.
- **Limites d'abonnement** : `rate_limits.five_hour.used_percentage` et `resets_at`, `rate_limits.seven_day.*`. Présents seulement pour Pro, Max et Ultra, et seulement après la première réponse. Les requêtes des sous-agents ne sont pas comptées.
- **Worktree** : `workspace.git_worktree`, `worktree.name`, `worktree.path`, `worktree.branch`, `worktree.original_cwd`.
- **Cache** : objet `prompt_cache` (lien documenté, champs non relus).

Option `refreshInterval` (minimum 1 s) pour un rafraîchissement temporisé.

**Stabilité** : documentée.

### 4. Transcripts JSONL

Source : https://code.claude.com/docs/en/sessions.md (section « Where transcripts are stored »)

- **Emplacement** : `~/.claude/projects/<projet>/<session-id>.jsonl`. `<projet>` est le chemin du répertoire de travail, les caractères non alphanumériques remplacés par `-`, tronqué à 200 caractères avec un hash au-delà.
- **Subagents** : `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl` (section « Resume subagents » de https://code.claude.com/docs/en/sub-agents.md). Le chemin est aussi fourni directement par `SubagentStop.agent_transcript_path`.
- **Format** : **explicitement non garanti**. La page dit que le format est interne et change entre versions. Les champs `uuid`, `parentUuid`, `isSidechain`, `message.usage` et `model` ne sont **pas documentés**.
- **Rétention** : 30 jours par défaut (`cleanupPeriodDays`).

**Recommandation** : ne pas deviner le nom du dossier projet. Récupérer `transcript_path` depuis les hooks ou la status line.

### 5. Sessions en arrière-plan et vue des agents

Source : https://code.claude.com/docs/en/agent-view.md (préversion de recherche, l'interface peut changer)

**Commandes** : `claude agents [--cwd] [--json [--all]]`, `claude --bg "<prompt>"`, `claude --bg --exec '<cmd>'`, `claude attach <id|nom>`, `claude logs <id|nom>`, `claude stop <id>`, `claude respawn`, `claude rm <id>`, `claude daemon status`.

**Sortie JSON documentée** de `claude agents --json` : `id`, `sessionId`, `name`, `cwd`, `kind`, `startedAt`, `state` (`working`, `blocked`, `done`, `failed`, `stopped`), `status` (`busy`, `waiting`, `idle`, présent si le processus est vivant), `waitingFor`, `pid`.

**Fichiers internes** : `daemon/roster.json`, `jobs/<id>/state.json`, `daemon.log`. La page les déclare **explicitement non stables** : `daemon/roster.json` et `jobs/<id>/state.json` ne doivent pas être lus.

**Non documenté** : une API programmatique hors CLI, le protocole du superviseur, le schéma complet de `--json`, les codes de sortie.

**Remote Control** : `claude remote-control` (alias `rc`) lance un serveur. Source : https://code.claude.com/docs/en/remote-control.md. Je n'ai pas trouvé de fichier d'état local ni d'API pour un outil tiers.

### 6. CLI et SDK

Sources : https://code.claude.com/docs/en/headless.md, https://code.claude.com/docs/en/cli-reference.md, https://code.claude.com/docs/en/agent-sdk/streaming-vs-single-mode.md

- **Lancer** : `claude -p --output-format stream-json --verbose --include-partial-messages`. Le champ `parent_tool_use_id` permet de rattacher les messages d'un subagent. `--bg` ne se combine pas avec `-p`.
- **Identifiant** : `--session-id <UUID>` impose l'identifiant ; `-n/--name` et `/rename` nomment la session.
- **Reprendre** : `--resume <id|nom|chemin .jsonl>`, `--continue`, `--fork-session` (nouvel identifiant), `/branch`.
- **Envoyer un message** : `claude --resume <session> "prompt"` envoie le prompt à une session en arrière-plan ; `claude -p --resume` fait pareil. Pour un processus vivant, `--input-format stream-json` accepte des messages `type: "user"` sur stdin (documentée, mais le protocole d'entrée n'est pas détaillé dans ma lecture).
- **Interrompre** : SIGINT ou `interrupt()` du SDK termine le tour ; SIGTERM sort avec le code 143 sans résultat pour le tour.
- **Permissions** : `--permission-prompt-tool`, `--permission-prompts none`, `--permission-mode`. Le SDK TypeScript et Python expose `canUseTool`.
- **Agents** : `--agents <json>`, `--agent <nom>`.
- **Flux** : messages `system` (`init` avec modèle, outils, serveurs MCP, plugins ; `api_retry` ; `plugin_install`), `assistant`, `user`, `stream_event`, `permission_denied`, `result` (avec `total_cost_usd`).

**Stabilité** : documentée pour les flags et le flux. Les messages du SDK Python et TypeScript sont documentés séparément.

### 7. Plugins et mods

Source : https://code.claude.com/docs/en/plugins/mods/overview.md

Un **mod** est un plugin dont les hooks JS/TS s'exécutent dans le processus Claude Code. Il peut :
- dessiner un **panneau** à côté du transcript, une **bande** au-dessus du prompt, ou redessiner des éléments existants (spinner, ligne d'appel d'outil) ;
- observer, réécrire ou prendre en charge des événements (appels d'outil, prompts, tours) ;
- ajouter une commande `/xxx`.

Installation : `/plugin install <nom>@<marché>` ou `claude plugin install`. Version requise : Claude Code v2.1.287 ou plus.

**Limites** :
- les mods ne dessinent rien en `claude -p` ni dans le SDK ; leurs hooks s'y exécutent ;
- pas de notifications OS documentées comme surface dédiée ;
- la page ne précise pas le statut de maturité (stable ou préversion).

Les **plugins** ajoutent des hooks, skills, agents et serveurs MCP (https://code.claude.com/docs/en/plugins/components.md). Les **settings hooks** et la **status line** restent les surfaces les plus simples pour un outil externe.

### 8. Coût et limites

Source : https://code.claude.com/docs/en/costs.md

- **`/usage`** (session) : coût total, durée, lignes modifiées, tokens par modèle, ligne `Prompt cache`. Le coût est **calculé localement** au tarif catalogue, sauf si `modelPricing` est défini par l'administrateur. Ce n'est pas une facture.
- **Limites d'abonnement** : `/usage` les affiche, et la status line les expose via `rate_limits`. L'API de l'endpoint d'usage n'est **pas documentée**.
- **Fichier local** : `~/.claude/usage-data/report.html` est produit par `/insights` (rapport HTML, pas une source temps réel).
- **Par session** : `claude -p --output-format json` renvoie `total_cost_usd`.
- **Par utilisateur (équipes)** : OpenTelemetry, ou l'API Analytics des plans Enterprise et Console.

## Tableau : besoin du tableau de bord, meilleure source, stabilité

| Besoin | Meilleure source officielle | Stabilité |
|---|---|---|
| Liste des sessions vivantes et leur état | `claude agents --json [--all]` | Documentée (champs listés) ; fichiers `daemon/`, `jobs/` = fragiles |
| Session qui attend une permission | Hook `PermissionRequest`, `Notification` (`permission_prompt`, `agent_needs_input`) | Documentée ; fin d'attente = observée |
| Session qui attend une réponse (question) | `Notification` (`idle_prompt`, `elicitation_dialog`), `PreToolUse` sur `AskUserQuestion` | Documentée ; le dernier point est déduit |
| Début, fin, reprise de session | Hooks `SessionStart` (`source`), `SessionEnd` (`reason`) | Documentée |
| Sous-agents : début, fin, transcript | Hooks `SubagentStart`, `SubagentStop` (`agent_transcript_path`) | Documentée |
| Historique détaillé des messages | Transcripts JSONL | **Fragile** (format interne, non garanti) |
| Coût d'une session | Status line `cost.total_cost_usd`, OTel `claude_code.cost.usage` | Documentée (estimation client) |
| Tokens et contexte | Status line `context_window`, OTel `claude_code.token.usage` | Documentée |
| Limites d'abonnement 5 h / 7 j | Status line `rate_limits` (Pro, Max, Ultra seulement) | Documentée ; absente hors abonnement |
| Durée et activité | OTel `claude_code.active_time.total`, status line `cost.total_duration_ms` | Documentée |
| Décisions de permission (historique) | OTel `claude_code.tool_decision` | Documentée |
| Lancer une session | `claude --bg`, `claude -p --output-format stream-json` | Documentée |
| Reprendre, bifurquer | `--resume`, `--continue`, `--fork-session`, `/branch` | Documentée |
| Envoyer un message à une session en arrière-plan | `claude --resume <id> "prompt"` | Documentée |
| Envoyer un message à un processus vivant | `--input-format stream-json` ou SDK en mode streaming | Documentée, protocole à valider |
| Interrompre | SIGINT, `interrupt()` du SDK | Documentée |
| Nommer une session | `-n`, `/rename`, `--session-id` (UUID) | Documentée |
| Panneau dans l'interface | Mods (panneau, bande, commande) | Documentée ; maturité non précisée |
| Identifier l'arbre des sous-agents | `agent_id`, `parent_tool_use_id` (stream-json), `agent_transcript_path` | Documentée |

**Conseil d'architecture** : combiner les hooks `http` (événements en temps réel vers le serveur local), `claude agents --json` (état de l'ensemble) et la status line (coût, limites). Ne pas parser les fichiers `daemon/` ni les JSONL pour des champs non documentés : ils servent de secours, pas de source.

Sources principales : https://code.claude.com/docs/en/hooks.md ; https://code.claude.com/docs/en/monitoring-usage.md ; https://code.claude.com/docs/en/statusline.md ; https://code.claude.com/docs/en/sessions.md ; https://code.claude.com/docs/en/agent-view.md ; https://code.claude.com/docs/en/headless.md ; https://code.claude.com/docs/en/cli-reference.md ; https://code.claude.com/docs/en/sub-agents.md ; https://code.claude.com/docs/en/costs.md ; https://code.claude.com/docs/en/plugins/mods/overview.md ; https://code.claude.com/docs/en/remote-control.md
