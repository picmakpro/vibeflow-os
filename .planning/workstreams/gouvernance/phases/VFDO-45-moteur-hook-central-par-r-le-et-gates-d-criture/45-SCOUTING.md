# Phase 45 — Scouting (recherche doc des hooks et cartographie du dépôt)

**Date des mesures :** 2026-09-29.
**Produit par :** deux recherches en lecture seule, dispatchées par `vf-dev-manager` (nœud
`recherche-hooks` du plan de bataille). Agents `a4ec2e564f891b2d1` (recherche doc, ADR-045) et
`a82d463c806d09302` (cartographie du dépôt).
**Pourquoi ce fichier existe :** les deux rapports sont arrivés dans le contexte du manager, qui a
été coupé par un `/clear` avant d'écrire quoi que ce soit sur disque. Leur texte intégral a été
retrouvé dans la transcription de la session (`93f2c252…`). Il est reporté ici pour que le
planificateur et les juges lisent le disque plutôt qu'un contexte perdu.
**Limite :** les numéros de ligne `hooks.md l.NNN` renvoient à des copies des pages officielles
téléchargées le 2026-09-29 dans un dossier temporaire du poste, qui ne survivra pas. La source
stable est la page officielle et sa section, citées à côté. Version de Claude Code sur le poste :
**2.1.284** (`claude --version`), qui est aussi la dernière entrée du CHANGELOG officiel.

## A. Recherche doc — contrat du harnais pour un hook fail-closed

Sources : pages officielles `https://code.claude.com/docs/en/{hooks,sub-agents,tools-reference,worktrees,settings,headless}`,
CHANGELOG officiel (raw GitHub), issues GitHub lues par `gh`. context7 n'a pas été interrogé : les
pages officielles datées du jour sont plus fraîches.

| # | Question | Réponse | Source | Confiance |
|---|---|---|---|---|
| 1a | `agent_type` / `agent_id` en PreToolUse | Oui, ce sont des champs communs à tous les événements. `agent_id` n'est présent que dans un sous-agent. `agent_type` est présent avec `--agent` ou dans un sous-agent, et le type du sous-agent l'emporte sur `--agent`. | hooks § Common input fields | documenté |
| 1b | Depuis quand | v2.1.69 (« Added `agent_id` … and `agent_type` … to hook events »). | CHANGELOG | documenté |
| 1c | Fil principal | Les deux clés sont **absentes**, pas vides, sans `--agent`. Avec `claude --agent X` : `agent_type="X"` et pas d'`agent_id`. Exception : SubagentStop des agents internes porte `agent_type=""`. | hooks § Common input fields, § SubagentStop | documenté |
| 1d | Valeur | Le `name:` du frontmatter, pas le nom de fichier. Les agents intégrés portent leur nom (`Explore`, `general-purpose`, `Plan`). Le `:` est interdit dans `name` depuis v2.1.218. | hooks § SubagentStart ; sub-agents | documenté |
| 1e | Agent de plugin | Préfixe `plugin:agent`. Un matcher doit être ancré (`^p:a$`), car le `:` fait passer le matcher en regex. **Constaté sur le poste** : les agents VibeFlow apparaissent sans préfixe (installés comme agents user ou projet), ceux de fileflow et impeccable avec préfixe. | hooks ; sub-agents | documenté + constaté |
| 2a | Forme du refus | `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"…"}}` sur stdout, exit 0. Précédence entre hooks : `deny > defer > ask > allow`. Les champs `decision`/`reason` racine sont dépréciés pour PreToolUse. | hooks § PreToolUse decision control | documenté |
| 2b | `exit 2` | Bloque toujours, même avec un JSON `allow`. stderr devient la raison. | hooks § Exit code 2 | documenté |
| 2c | `exit 1` | **Non bloquant**, sauf si stdout porte un JSON valide, qui décide alors seul. | hooks § Exit codes | documenté |
| 2d | JSON invalide | Non bloquant (sauf exit 2). | hooks | documenté |
| 2e | Timeout | 600 s par défaut pour `command`. Un PreToolUse qui dépasse est annulé et **ne bloque pas** (« don't count on a stalled hook to act as a gate »). | hooks § Timeouts | documenté |
| 2f | Script introuvable | Non bloquant : le shell rend 127, l'action continue. La doc prévient : « a mistyped path … leaves the gate silently disabled ». Pour `node` (« Cannot find module ») : déduit, même effet. | hooks ; issues #82323 (ouverte), #81458 | documenté (variante node déduite) |
| 2g | Réglage fail-closed | **Aucun** pour un hook `command` (demande ouverte #82323). | hooks | le réglage n'existe pas |
| 3a | `Task` ou `Agent` | L'outil s'appelle `Agent` depuis v2.1.63. `Task(...)` reste un alias dans les réglages et les définitions d'agents. Pour un **matcher de hook**, l'alias n'est pas documenté. | sub-agents ; tools-reference | documenté / non documenté |
| 3b | Contradiction | #69545 (fermée) : `matcher:"Agent"` ne déclenche pas. #95769 (ouverte, 2026-09-21) : `"Task"` déclenche, `"Agent"` non. Le garde GSD du poste matche `Agent\|Task` et accepte les deux `tool_name`. | issues ; `~/.claude/hooks/gsd-agent-isolation-guard.js` | contradictoire |
| 3c | Autres outils | `MultiEdit` n'est plus listé. `NotebookEdit` existe. `file_path` de Write/Edit/Read est toujours absolu. | tools-reference ; hooks | documenté |
| 3d | Dispatch imbriqué | PreToolUse se déclenche pour tout outil d'un sous-agent, avec l'`agent_type` de l'appelant. Non écrit pour le cas `Agent` imbriqué. `tool_input.subagent_type` est comparé sans casse ni séparateurs depuis v2.1.140 : à normaliser côté hook. | hooks ; sub-agents ; CHANGELOG | déduit |
| 4a | Hooks dans les sous-agents | Les hooks de settings, managed et plugins tournent dans les sous-agents. | hooks ; sub-agents | documenté |
| 4b | `hooks:` du frontmatter d'agent de plugin | **Ignorés.** Ceux d'un agent projet ne tournent qu'après acceptation de la confiance du dossier. | sub-agents | documenté |
| 5a | `$CLAUDE_PROJECT_DIR` | Racine où la session a démarré. **Ne suit pas `EnterWorktree`** ; seul le `cwd` du payload suit. | hooks ; worktrees | documenté |
| 5b | Session lancée dans le worktree | `$CLAUDE_PROJECT_DIR` nomme le worktree (#97836). Scripts de hook périmés dans un vieux worktree : #97349. | issues | constaté (issues) |
| 6a | `SubagentStop` | Peut refuser (`decision:"block"` ou exit 2). Depuis v2.1.271 le rapport rendu par `SubagentHandback` est dans `tool_input.message` d'un hook matché sur cet outil, pas dans `last_assistant_message`. | hooks § SubagentStop | documenté |
| 6b | `TaskCompleted` | Refuse par exit 2. Concerne `TaskUpdate` et les équipes d'agents, pas le dispatch `Agent`. | hooks | documenté |
| 6c | `FileChanged` | Ne peut rien bloquer ; tourne après l'écriture ; matcher = noms littéraux. | hooks | documenté |
| 7 | Contournements | `disableAllHooks` (un `--settings '{"disableAllHooks":true}'` passe devant projet et local), `allowManagedHooksOnly` (managed), `--bare` en `-p`. Seul un hook managed résiste. | hooks ; settings ; headless | documenté |
| 8 | `session_id` en sous-agent | Celui du parent (#76726, ouverte) ; les refus en sous-agent ne remontent pas au parent. | issue | non documenté |

### Conséquences pour un hook fail-closed

1. Le script doit fermer lui-même : toute erreur interne doit finir en `deny` explicite. Le harnais
   laisse passer sur tous les autres échecs (exit 1, crash de l'interpréteur, 127, timeout, JSON
   invalide).
2. Un hook qui ne démarre pas (chemin faux, script absent, copie périmée d'un autre worktree) ne se
   rattrape pas depuis le hook. Deux parades : une **commande enregistrée** qui teste elle-même la
   présence du script et de `python3` et émet le refus ; et un **canary** (un appel qui doit être
   refusé), seule preuve qu'il tourne.
3. Rôle : `agent_id` absent veut dire fil principal ; `agent_type` donne le `name:`, préfixé
   `plugin:` pour un agent de plugin. Rien ne se fonde sur `session_id`. Normaliser
   `tool_input.subagent_type`. La politique vit dans les réglages, pas dans le frontmatter des
   agents de plugin (ignoré).
4. Matcher `Agent|Task`, accepter les deux `tool_name`. Ne pas compter sur `MultiEdit`.
5. Un gate du dépôt reste contournable (`disableAllHooks`, `--bare`, réglage local). Il rend visible
   et trace, il ne verrouille pas.

## B. Cartographie du dépôt (lecture seule, racine = ce worktree)

### B1. Déclaration et pose des hooks
- Hooks déclarés uniquement dans `plugin/<mod>/hooks/hooks.json`, pour 6 modules : conductor,
  consolidator, dev-orchestrator, infrastructure-audit, planning-core, software-architecture. Aucun
  `module.json` ne déclare de hook.
- Deux jetons de fragment : `{{VF_SCRIPTS}}` (forme shell `bash {{VF_SCRIPTS}}/x.sh`) et
  `{{VF_BASH}}` (forme exec `command` + `args`).
- Préfixe de `{{VF_SCRIPTS}}` (`plugin/_internal/vibeflow-update.sh:1828-1834`) : scope user
  `"$HOME"/.claude/scripts` ; project/local `"$CLAUDE_PROJECT_DIR"/.claude/scripts` ; `--target`
  `"<TARGET_ROOT>"/scripts`. En forme exec, `merge-hooks.sh` dérive `${CLAUDE_PROJECT_DIR}/…`
  (l.20-25, 204-222, 483-490).
- Les entrées `{{VF_BASH}}` vont dans `settings.local.json` (`merge-hooks.sh:362-367`), le reste
  dans `settings.json`. Dédup par basename, merge idempotent, retrait chirurgical.
- Scripts copiés dans `$TARGET_ROOT/scripts/` : `*.sh|*.mjs|*.js` exécutables, `*.txt|*.json` en
  données, `tests/` compris (`vibeflow-update.sh:1984-2054`). Un `.py` n'est pas posé (cf. P44-D-14).

### B2. Gardes existants
| Script | Événement · matcher | Refus | Dépendance manquante |
|---|---|---|---|
| conductor `guard-agent-write.sh` | PreToolUse · Write | JSON deny | python absent → exit 0 ; crash du checker → allow |
| conductor `guard-driver-lock.sh` | PreToolUse · Bash\|Write\|Edit | JSON deny | pas de lock → 0 ; `vf-portable` absent → 1 ; python absent → 17 (`vf_guard_unavailable`) ; payload imparsable → 0 |
| consolidator `guard-read-registres.sh` | PreToolUse · Read | JSON deny | python absent → 0 |
| consolidator `guard-bash-registres.sh` | PreToolUse · Bash | JSON deny | python absent → 0 |
| software-architecture `guard-file-size.sh` | PreToolUse · Edit\|Write | JSON deny | `vf-portable` absent → 1 ; python absent → 17 |
| planning-core `guard-planning-updated.sh` | **Stop** | exit 2 + stderr (contraire à DIV-2) | fail-open partout |

- Code 17 = `VF_GUARD_UNAVAILABLE_EXIT_CODE` (`vf-portable.sh:147-151`), marqueur dans
  `${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}/<script>.marker`.
  Trois appelants seulement.
- `check-guard-health.sh` (SessionStart) lit ces marqueurs ; il **n'exécute aucun garde**. **Aucun
  canary n'existe dans le plugin** (`git grep -i canary plugin scripts .github` : une sentinelle de
  test et un « canari » CI sur la lisibilité du moteur GSD, rien d'autre).
- `check-hook-paths.sh` n'examine que les chemins **absolus** : un `${CLAUDE_PROJECT_DIR}/…`
  manquant n'est pas vu.
- DIV-2 (`exit 2` fuit le chemin du script) : `32-TERRAIN.md:260-269`, repris par
  `guard-driver-lock.sh:22-25` et la spec moteur §5.1.
- Contrat de sortie des hooks du dépôt : `docs/HOOKS-CONTRAT-SORTIE.md` (6 entrées bloquantes sur 29).

### B3. `agent_type` dans le dépôt
- **Aucun script ne lit `agent_type` ni `agent_id` dans un payload.** L'`agent_id` de
  `driver-lock.sh` est un registre à part, alimenté en ligne de commande.
- Mesure antérieure (`32-TERRAIN.md` l.285, 329, 333, 290-292) : clés présentes seulement en
  sous-agent ; leur absence est le seul marqueur fiable du fil principal ; aucune variable `CLAUDE*`
  ne porte `agent_id` ; parsing en Python.

### B4. Rôles
- Aucune clé de rôle déclarée. Clés de frontmatter sur 41 agents : `vf-internal` (20),
  `disallowedTools` (6), `omitClaudeMd` (4)…
- **Juge (I5)**, `check-agents.sh:135-142, 908-922` : `disallowedTools` retire Write **et** Edit,
  aucune allowlist `Agent(...)`, `omitClaudeMd: true`. Correspondent : `quality-gate-client`,
  `content-clarity-judge`, `vf-design-judge`, `growth-quality-judge`. `vf-reviewer` et `vf-auditer`
  n'en sont pas (ils ont une allowlist).
- **Manager (I6)**, l.128-134, 893-906 : allowlist `Agent(...)` non vide, pas `vf-internal`,
  `SendMessage`. Les 5 managers.
- Dispatcheurs internes non managers : `vf-coder`, `vf-reviewer`, `vf-auditer`,
  `vf-test-orchestrator`.
- « Producteur » n'apparaît nulle part dans `plugin/`.
- 9 blueprints `plugin/*/content/agents/*.blueprint.md`, lintés par `check-blueprints.sh`.

### B5. Le moteur de la 44
- `recalc-planning.sh` : 0 succès ; 1 erreur ; 2 refus d'adhésion ; 3 refus GSD (détecté ou non
  concluant) ; 64 usage. `--read-only` rend toujours 0.
- Adhésion : `"planning_version": "cycles-v1"` dans `config.json`, égalité stricte. Les gabarits
  v2 portent `"2.0"` (`config.template.json:2`) et `planning_version: 1.0` (`STATE.template.md:2`).
- `detect-gsd-engine.sh` : 1 chaîne GSD absente ; 0 moteur GSD actif ; **2 migration** ; 3 terrain
  libre ; 64 usage. **2** = `.planning/STATE.md` porte la clé `planning_version` **et** un signal de
  code existe dans le cwd (package.json, go.mod, Cargo.toml, pyproject.toml, pom.xml,
  build.gradle(.kts), composer.json, Gemfile, tsconfig.json, Package.swift, `*.xcodeproj`)
  (l.171-188). Le recalcul traduit 2 en `non-concluante`, exit 3. Le STATE.md généré ne porte pas
  `planning_version` : le 2 vient d'un STATE.md du socle v2 préexistant.
- `phases_trace` et `gates` : jamais lus par le moteur (défauts `false` du gabarit v2).
- Fichiers générés : `INDEX.md`, `STATE.md`, `cloture.log` (ajout seul), `.recalc-cache.json`.
  Marqueur de clôture de plan : `CLOTURE.md`. `VERDICT.md` : `juge`, `hash`, `tentative`, `score`,
  `constats` ; `hash` et `tentative` lus, non vérifiés (46). G6 renvoyé à la 45
  (`modele-cycles.md:692-693`).

### B6. Hooks dans les worktrees
- `/Users/…/vibeflow-os/.claude/settings.local.json` : 25 commandes, toutes via
  `$CLAUDE_PROJECT_DIR` (le BACKLOG en annonce 22). `settings.json` : 21, toutes via
  `"$CLAUDE_PROJECT_DIR"/.claude/scripts/…`.
- Un script absent donne 127 (bash) ou « Cannot find module » (node) : ni 2 ni deny, l'action
  passe (`BACKLOG.md:1116-1128`).
- Dans ce worktree, `.claude/hooks` et `.claude/scripts` sont des **liens symboliques** vers le
  checkout principal (commit `5a425dd`, `BACKLOG.md:1130-1144`), seul contournement en place.

### B7. CI
- 4 jobs `ubuntu-latest` (tests, gates, lab-frais, lab-frais-arme). Pas de macOS, pas de Windows
  réel.
- Suites découvertes par `find plugin scripts -type f -path '*/tests/test-*.sh' | sort` ; zéro
  suite = échec. Les 9 suites de planning-core tournent déjà sous Linux.

### B8. Préfixes d'exigences
- `FABR-01..10` et `MOTR-01..18` sont posés dans le REQUIREMENTS du compartiment ; aucun n'est
  rattaché à la 45.
- Candidats libres (0 fichier sur tout le dépôt, `git grep -lE '<P>-[0-9]'` et `grep -rliE`) :
  **GATE**, HOOK, GARD, ROLE, GTE, MGAT.

## C. Points d'attention pour le cadrage et le plan

1. Aucun hook ne lit encore `agent_type` ; le fil principal ne se reconnaît qu'à l'absence de la clé.
2. Aucun canary n'existe ; `check-guard-health` ne voit que 3 gardes.
3. Un script de hook absent laisse passer sans signal ; en worktree, seuls des liens posés à la main
   l'évitent. La session qui a produit ce scouting avait démarré dans un autre worktree
   (`gouvernance-44`, nom du dossier temporaire) : `$CLAUDE_PROJECT_DIR` y visait les copies de ce
   worktree-là. Déduit, non vérifié.
4. `guard-planning-updated.sh` bloque par exit 2 sur Stop, contre DIV-2 ; son retrait n'est prévu
   qu'avec les gates et sous validation humaine (ADR-031).
5. Un lab métier dont le STATE.md du socle v2 porte `planning_version` et qui contient un fichier
   de code voit le détecteur rendre 2, donc le recalcul refuser l'écriture (exit 3).
6. `vf-coder` (worker interne) dispatche les briques GSD par construction : la ligne « Worker :
   tout dispatch refusé » de la spec fabrique §5, appliquée à tous les labs, casserait la chaîne dev.
   Le runtime n'applique pas les allowlists `Agent(...)` (mesuré le 2026-09-17).
