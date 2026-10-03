# Phase 46 — Recherche documentaire : TaskCompleted, SubagentStop, FileChanged

> Nœud `recherche-hooks-46`, mission `vf-dev-manager-p46-cadrage`, mandat ADR-045. Rien n'est codé ici.
> Consultation : 2026-10-03. Version locale : `claude --version` → `2.1.288 (Claude Code)`.

**Sources.** Le texte brut des pages a été récupéré par `curl` sur le `.md` de chaque page. WebFetch
a été écarté : il résume la page et, à l'essai, prêtait à TaskCompleted un `decision: "block"` que la
page ne contient pas.

- **[H]** https://code.claude.com/docs/en/hooks, avec la section citée.
- **[T]** https://code.claude.com/docs/en/tools-reference, § Task tool availability.
- **[AT]** https://code.claude.com/docs/en/agent-teams.
- **[PR]** https://code.claude.com/docs/en/plugins-reference.
- **[CL]** https://code.claude.com/docs/en/changelog, versions citées.
- **#nnnnn** : une issue `anthropics/claude-code`, lue avec `gh issue view`. Son état date du 2026-10-03.

**Statuts.** **D** = documenté. **O** = observé localement. **Dé** = déduit. **NT** = non trouvé.

---

## 0. Le fait qui change le cadrage

| # | Constat | Source | Statut |
|---|---|---|---|
| 0a | Depuis **v2.1.268**, les outils `TaskCreate/TaskGet/TaskUpdate/TaskList` (et `TodoWrite`) ne sont fournis **par défaut** que sur Claude 3.x, Opus 4.0–4.7, Sonnet 4.0–4.6 et Haiku 4.5. Sur tout autre modèle, il faut l'activer : `CLAUDE_CODE_ENABLE_TODO_TOOLS=1`, ou nommer l'outil dans `--allowedTools`/`--tools`. Ils restent fournis partout en sessions d'arrière-plan et cloud. | [T] ; [CL] 2.1.233 (retrait sur Opus 4.8, Sonnet 5, Fable 5, Mythos 5) et 2.1.268 | D |
| 0b | « Claude Code gives a subagent the tools only when your session has them. » Même règle pour un coéquipier in-process d'une équipe d'agents. | [T] | D |
| 0c | Sur ce poste, la session tourne sur Opus 5.5 (`"model": "opus[1m]"` dans `~/.claude/settings.json`). `CLAUDE_CODE_ENABLE_TODO_TOOLS` n'est pas positionnée (`echo` → `unset`). Aucun outil `Task*` n'apparaît dans la liste d'outils de ce sous-agent. | commandes locales ; liste d'outils | O |
| 0d | **Conséquence** : sur un modèle récent, sans activation explicite, **TaskCompleted ne se déclenche jamais**, puisque l'outil qui le porte n'existe pas. Pour TaskCreated, la page le dit en toutes lettres : « In a session without the Task tools, this event doesn't fire ». | [H] § TaskCreated ; 0a–0c | D (TaskCreated) / Dé (TaskCompleted) |

## 1. TaskCompleted

| # | Point | Contenu | Source | Statut |
|---|---|---|---|---|
| 1.1 | Déclenchement | Deux cas : « when any agent explicitly marks a task as completed through the TaskUpdate tool », ou « when an agent team teammate finishes its turn with in-progress tasks ». **Ni `TodoWrite` ni la fin d'un `Agent`** ne le déclenchent. | [H] § TaskCompleted | D |
| 1.2 | Sous-agent | « any agent » couvre aussi un sous-agent qui appelle `TaskUpdate`, à condition que la session ait les outils (0b). | [H] ; [T] | Dé |
| 1.3 | Introduction | v2.1.33 (« Added `TeammateIdle` and `TaskCompleted` hook events for multi-agent workflows »). `continue:false` pris en compte à partir de v2.1.69. | [CL] | D |
| 1.4 | Payload | Champs communs (`session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`, plus `agent_id`/`agent_type` dans un sous-agent ou sous `--agent`), puis `task_id`, `task_subject`, et facultativement `task_description`, `teammate_name` et `team_name` (déprécié). **Ni livrables, ni métadonnées libres, ni statut précédent.** | [H] § TaskCompleted input, § Common input fields | D |
| 1.5 | Matcher | Aucun : « fire on every occurrence ». | [H] § Matcher patterns | D |
| 1.6 | Refus | **`exit 2`** : la tâche n'est pas close et le stderr revient au modèle. Hook `prompt`/`agent` avec `ok:false` : la raison revient en erreur d'outil et le tour continue. `continue:false` est **ignoré** quand c'est `TaskUpdate` qui déclenche. **Aucune ligne de doc** n'attribue `permissionDecision` ni `decision:"block"` à cet événement : le tableau « Decision control » ne prévoit pour lui que « Exit code or `continue: false` ». | [H] § TaskCompleted decision control, § Decision control, § Prompt-based hooks | D (`decision:block` : NT) |
| 1.7 | Boucle | Aucun plafond documenté pour un refus en série sur `TaskUpdate`. Le plafond de 8 refus consécutifs (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`) n'est écrit que pour Stop et SubagentStop. | [H] § Stop input ; [CL] 2.1.143 | NT (cap) |
| 1.8 | Échec | `exit 1` ou autre code avec stdout vide : erreur non bloquante, **l'action passe**. Script introuvable (127) : même effet, et la doc prévient qu'un chemin faux « leaves the gate silently disabled ». Timeout (600 s par défaut pour `command`) : le hook est annulé, sa sortie jetée, il ne rend pas de décision. Un JSON invalide ne bloque pas, sauf avec exit 2. | [H] § Other exit codes, § Timeouts, § Exit code 2 | D |
| 1.9 | Piège stderr | #60490 (fermée NOT_PLANNED le 2026-06-18) : pour Stop, SubagentStop, TaskCompleted et TeammateIdle, un `exit 2` avec stdout vide et un stderr qui contient `no such file` ou `can't open` est **rétrogradé en non bloquant**. Le harnais croit alors que le script est absent. Non revérifié sur 2.1.288. | #60490 | constaté (issue) |

## 2. SubagentStop

| # | Point | Contenu | Source | Statut |
|---|---|---|---|---|
| 2.1 | Déclenchement | « when a Claude Code subagent has finished responding ». Se déclenche aussi pour les agents internes du harnais (suggestions de prompt, `/btw`), avec un `agent_type` vide ou égal à l'agent de session. | [H] § SubagentStop input | D |
| 2.2 | Introduction | v1.0.41 (séparé de Stop). `agent_id` et `agent_transcript_path` en 2.0.42, `last_assistant_message` en 2.1.47, `additionalContext` en 2.1.163. | [CL] | D |
| 2.3 | Payload | Communs, plus `stop_hook_active`, `agent_id`, `agent_type`, `agent_transcript_path`, `last_assistant_message`, `background_tasks` et `session_crons`. | [H] § SubagentStop input | D |
| 2.4 | **Le rapport ne passe pas par là** | Depuis **v2.1.271**, un sous-agent qui dispose de `SubagentHandback` rend son rapport par cet outil. `last_assistant_message` ne contient alors **que le texte de clôture**. Le rapport se lit dans `tool_input.message` d'un `PreToolUse`/`PostToolUse` matché sur `SubagentHandback`. Cet outil n'est fourni qu'en **mode auto**, aux sous-agents locaux hors forks. | [H] § SubagentStop ; [T] tableau des outils | D |
| 2.5 | Matcher | Sur `agent_type`, mêmes valeurs que SubagentStart ; pour un agent de plugin, `^plugin:nom$`. Un matcher nommé ne capte pas un `agent_type` vide. | [H] § Matcher patterns, § SubagentStop | D |
| 2.6 | Refus | `decision:"block"` + `reason`, ou `exit 2` : le sous-agent **continue**, et `reason`/stderr devient sa prochaine instruction. `additionalContext` produit le même effet sans être étiqueté comme erreur. Hook `prompt` : `ok:false`, sauf si `impossible:true`. | [H] § SubagentStop, § Stop decision control | D |
| 2.7 | Boucle | Plafond natif : après **8 continuations consécutives**, Claude Code passe outre et termine (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`). Ajouté en v2.1.143. `stop_hook_active` vaut `true` dès la 2e relance. | [H] § Stop input, § Stop decision control ; [CL] 2.1.143 ; #83365 | D |
| 2.8 | Échec | Même régime que 1.8 : fail-open sur exit 1, 127, timeout et JSON invalide. Piège 1.9 compris. | [H] ; #60490 | D |
| 2.9 | Bugs ouverts | #92716 : pas de SubagentStop quand le sous-agent est tué (`TaskStop`, « Exit and stop tasks »). #78463 : pas de SubagentStop en rafale d'erreurs d'API. #89555 : `agent_id` différent de celui de SubagentStart. #91910 : déclenché pour le résumeur interne. #82249 (2.1.220) : non déclenché pour un `Agent` en arrière-plan, mais #83365 le contredit sur la même version. #87065 (matcher contourné quand `agent_type` est vide) est corrigé en **2.1.275** d'après [CL]. | issues ; [CL] 2.1.275 | constaté (issues) |

## 3. FileChanged

| # | Point | Contenu | Source | Statut |
|---|---|---|---|---|
| 3.1 | Déclenchement | « Claude Code detects changes with a filesystem watcher, not by inspecting tool calls ». Le hook part quel que soit l'auteur de l'écriture : Write, Edit, Bash ou process extérieur. Il tourne **après** l'écriture. Événement asynchrone et autonome, hors boucle d'outils. | [H] § FileChanged ; diagramme du cycle de vie | D |
| 3.2 | Introduction | v2.1.83, avec CwdChanged. | [CL] | D |
| 3.3 | Payload | Communs, plus `file_path` (absolu) et `event` (`change`, `add` ou `unlink`). **Pas d'auteur, pas de pid, pas d'outil.** | [H] § FileChanged input | D |
| 3.4 | Watch-list | Le matcher, découpé sur `\|`, enregistre chaque segment comme « **literal filename in the working directory** » : pas de regex, pas de glob, pas de chemin profond. `"*"` désigne un fichier nommé `*`. Pour des chemins arbitraires, un hook SessionStart, CwdChanged ou FileChanged renvoie `watchPaths`, une liste de **chemins absolus** qui **remplace** la liste dynamique. Le watcher ne démarre que si quelque chose lui nomme un fichier. | [H] § FileChanged, § CwdChanged output, § SessionStart decision control | D |
| 3.5 | Récursivité | La doc parle de fichiers. #91634 décrit un `watchPaths` pointé sur un **dossier** et enregistré **récursivement** : 137 000 fichiers en NFS ont bloqué le fil principal de 20 à 45 s au démarrage. | [H] ; #91634 (ouverte) | NT (doc) / constaté (issue) |
| 3.6 | Sortie | Aucun contrôle de décision : « can't block the file change ». Lus : `watchPaths` et `systemMessage`, ce dernier en notification terminal, **absent du flux SDK**. `exit 2` : le stderr va **à l'utilisateur seulement**, le modèle ne voit rien. `asyncRewake: true` + `exit 2` réveille Claude et lui montre le stderr en system-reminder. | [H] § FileChanged output, § Exit code 2 per event, § Common fields | D |
| 3.7 | Échec | Rien à rater côté action, puisqu'il ne peut rien bloquer. Un échec est une **trace perdue** en silence. | [H] | Dé |
| 3.8 | Bugs | **#95440** (ouverte, 2.1.270, macOS) : après **n'importe quel `cd`** dans la session, FileChanged **ne se déclenche plus**, ni pour le matcher ni pour un `watchPaths` renvoyé par CwdChanged, et rien ne l'annonce. #90436 (ouverte, Windows) : `unlink` hors du `cwd` non vu. #44925 (fermée NOT_PLANNED) : écritures Bash non vues. **#63148** (2.1.153, fermée comme doublon de #16288, toujours ouverte) : un FileChanged ou CwdChanged **déclaré par plugin** ne se déclenche pas, alors que la même déclaration dans `settings.json` fonctionne. #80692 : `EnterWorktree` ne déclenche pas CwdChanged. | issues | constaté (issues) |
| 3.9 | Poste | `~/.claude/settings.json` déclare déjà un FileChanged `matcher: "config.json"` (GSD, `gsd-config-reload.js`) : le watcher tourne donc déjà sur toutes les sessions de ce poste. | `sed -n 435,446p ~/.claude/settings.json` | O |

## 4. TaskCreated (complément)

Il se déclenche sur `TaskCreate` seulement, et pas sans les outils Task. Introduit en v2.1.84. Il
n'a pas de matcher et reçoit le même payload que TaskCompleted. Il refuse par `exit 2` **ou**
`decision:"block"` : la tâche est supprimée et le message revient au modèle. `continue:false` est
ignoré. Sources : [H] § TaskCreated, [CL] 2.1.84. Statut : D. C'est **le seul** des deux événements
de tâche pour lequel un refus JSON est documenté.

## 5. Questions transverses

| # | Point | Contenu | Source | Statut |
|---|---|---|---|---|
| 5.1 | Filtrage avant lancement | Le matcher est évalué sur un champ du JSON d'entrée avant de lancer les groupes de hooks. Pour TaskCompleted (sans matcher), **chaque** `TaskUpdate` à `completed` lance le processus. Pour FileChanged, seuls les fichiers de la watch-list sont surveillés. | [H] § Matcher patterns | D (principe) / Dé (TaskCompleted : coût à chaque clôture) |
| 5.2 | Hooks de plugin | `hooks/hooks.json` ou `hooks` inline dans `plugin.json`, même forme que `settings.json`, tous les événements du renvoi [H]. Les hooks de plugin tournent aussi dans les sous-agents. **En revanche**, les `hooks:` du frontmatter d'un agent de plugin sont ignorés (45-SCOUTING 4b). #16288 (ouverte) : un `hooks.json` référencé depuis `plugin.json` n'est pas chargé ; contournement rapporté : inline dans `plugin.json` ou fichier conventionnel. | [PR] ; [H] § hook locations ; #16288 | D / constaté (issue) |
| 5.3 | Neutralisation | `disableAllHooks` (même via `--settings`) et `--bare` en `-p` coupent les trois. Seul un hook managed résiste. | [H] § Disable or remove hooks ; `claude --help` | D / O |
| 5.4 | Sonde locale | Une sonde `claude -p --model haiku` sur des hooks de test sous le scratchpad a été préparée (`…/scratchpad/probe46/`). **Le classifieur de session l'a refusée** (« a worktree-isolated session's git operations must target its own worktree »). Elle n'a **pas été contournée** : aucun comportement de 2.1.288 n'est observé en direct. | refus du classifieur | — |

---

## Implications pour le cadrage de la 46

**1. Ce que G3 et G4 sur TaskCompleted peuvent garantir.**

- *Si* la session a les outils Task, le refus `exit 2` empêche la clôture par `TaskUpdate`, avec
  la raison renvoyée au modèle. C'est vrai dans le fil principal et dans un sous-agent qui hérite
  des outils.
- C'est un **garde de passage**, pas un garde d'existence. Il juge le geste « je clos », jamais
  « le travail est fini ».

**2. Ce qu'ils ne peuvent pas garantir.**

- (a) **Sur Opus 4.8+, Sonnet 5, Fable 5 et Mythos 5, sans `CLAUDE_CODE_ENABLE_TODO_TOOLS=1`,
  l'événement n'existe pas.** C'est précisément la configuration de ce poste et, par défaut, de tout
  lab récent.
- (b) Un lab métier qui ne passe jamais par `TaskUpdate` clôt sans jamais rencontrer G3/G4. Il le
  fait en marquant `done` dans un fichier, par un rapport `Agent` ou par un `SubagentHandback`.
  L'affirmation de la spec §5 « l'agent ne peut pas l'esquiver » ne vaut **que si** la clôture
  métier est *définie* comme un `TaskUpdate`.
- (c) Le payload ne porte que `task_id`, `task_subject` et `task_description` : le lien entre la
  tâche et ses livrables déclarés doit être **encodé par le moteur**, par une convention de sujet ou
  un index `task_id → livrables` écrit à la création. Sans ce lien, le hook ne sait pas quoi
  vérifier.
- (d) La spec §5.1-1 (« refus par `permissionDecision: deny`, jamais par le code de sortie ») est
  **inapplicable** à TaskCompleted : seul `exit 2` est documenté. La mesure DIV-2 (« exit 2 fuit le
  chemin ») doit être traitée dans le message lui-même, sans chemin absolu. Il ne doit pas non plus
  contenir `no such file` ni `can't open` (#60490).
- (e) Fail-open sur exit 1, 127, timeout et `disableAllHooks` : le canary C-16 doit couvrir
  TaskCompleted comme les gates de la 45.

**3. Alternatives d'événement pour la clôture.**

- **`PreToolUse` sur l'outil de clôture du moteur.** Une commande enregistrée ou un script du
  moteur (`vf-close` / `bash …/close.sh`) refuse par `permissionDecision: deny`. Le mécanisme est
  le même que pour les gates de la 45, il est indépendant du modèle et couvre aussi `Write`/`Edit`
  d'un `STATE`/`VERDICT` vers `done`. Il ne s'esquive que par un chemin non gardé, que D1 trace.
- **`PreToolUse` sur `SubagentHandback`.** Il lit `tool_input.message`, c'est-à-dire le vrai
  rapport depuis 2.1.271, et peut le refuser par `deny`. **C'est le bon point pour G4′**, pas
  SubagentStop, dont `last_assistant_message` ne contient plus le rapport en mode auto. Hors mode
  auto (pas de `SubagentHandback`), le repli est SubagentStop ou `PostToolUse` sur `Agent` (le
  rapport est dans `tool_response.content`, mais `PostToolUse` ne bloque pas). Un `Agent` lancé en
  arrière-plan ne fournit **aucun** rapport à `PostToolUse` (`async_launched`).
- **SubagentStop pour G4′** reste possible : refus par `decision:"block"`, plafond natif de 8. Il
  faut le borner : matcher par `agent_type` et ignorer `agent_type` vide.
- **Stop** (fil principal) peut servir de filet « pas de fin de tour avec une tâche ouverte non
  jugée ». Plafond de 8.
- **TaskCompleted reste utile en complément** pour les labs en équipes d'agents ou ceux qui activent
  les outils Task. Si le moteur en fait le gate principal, le cadrage doit **exiger et vérifier**
  `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` (preuve par canary). Cette décision revient à l'humain.

**4. D1 sur FileChanged.**

- Pour la watch-list, il faut un `SessionStart` qui renvoie des `watchPaths` absolus (`STATE.md`,
  `VERDICT.md`, livrables), énumérés **fichier par fichier**, jamais un dossier (#91634). Il faut
  aussi les re-émettre sur CwdChanged.
- Trois trous le rendent **non fiable comme seul témoin** : il est sourd après un `cd` (#95440,
  ouverte), il est peut-être muet quand il est déclaré par plugin (#63148/#16288), et il ne voit
  rien entre deux sessions.
- Le payload ne nomme pas l'auteur. Pour distinguer « écriture d'un outil » et « écriture
  extérieure », il faut croiser avec un journal `PostToolUse` : à déduire, à prototyper.
- Le modèle ne voit rien, sauf avec `asyncRewake` + `exit 2`.

**5. Coût hors adhésion, pour un lab qui n'utilise pas le moteur.**

- **TaskCompleted** : nul sans outils Task (l'événement ne naît pas). Avec les outils, un processus
  par clôture, sans matcher possible. Le script doit sortir en `exit 0` immédiat si le lab n'a pas
  adhéré.
- **SubagentStop** : un processus par fin de sous-agent, y compris pour les agents internes. Un
  matcher `agent_type` le réduit à zéro hors des agents du moteur (Dé).
- **FileChanged** : le watcher démarre **seulement si** une watch-list est nommée. Un lab non
  adhérent ne renvoie pas de `watchPaths`, donc le coût est nul (D). Sur ce poste, un watcher tourne
  déjà via GSD (3.9, O).
- **PreToolUse** sur un outil de clôture dédié : le matcher le filtre, donc un coût nul hors appel
  (D, principe).

**6. À mesurer en exécution, faute de sonde.**

Il reste quatre points à mesurer par une sonde autorisée, idéalement par un humain ou hors
worktree :

- le déclenchement de TaskCompleted sur 2.1.288 avec `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` ;
- la présence d'un plafond de boucle sur TaskCompleted ;
- FileChanged déclaré par plugin ;
- l'actualité de #95440 et de #60490.
