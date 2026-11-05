# Phase 72 : Lancer du travail depuis les cartes du cockpit — Recherche de cadrage

**Recherché le :** 2026-11-05 (worktree `.claude/worktrees/phase-72`, branche `feat/phase-72-lancer-depuis-cartes`, base `aff9f260` = `origin/main`)
**Domaine :** cockpit (`plugin/cockpit/`, module en `v1.3.2` sur main) : cartes Projet et Équipe, chat `/api/ask`, terminal Q (Phase 71), CLI Claude Code
**Confiance globale :** MOYENNE-HAUTE. Code lu cette session (chemins et lignes cités). Comportement de la CLI vérifié par `claude --help` (2.1.318) et la référence officielle. Deux points restent à sonder : un skill en prompt initial, `--agent vibeflow-head`.

## Résumé

La 72 n'a pas encore de CONTEXT ni d'exigences : `ROADMAP.md` dit « Requirements: TBD — posées au cadrage » et « Depends on: Phase 71 » [VERIFIED: .planning/workstreams/fiabilite/ROADMAP.md:475-476]. La question qui décide de la sécurité est celle-ci : **qui confirme un lancement, et dans quelle origine ?** Tout ce que la page Projet (P) peut demander au serveur, une charge XSS exécutée dans P peut le demander aussi. Le jeton de P est dans la page, et toute route `/api/*` de P ne vérifie que le Host, l'Origin de même origine et ce jeton [VERIFIED: plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs:508-514]. La Phase 71 a donc fermé le sens P → Q (P71-D-15). La suite `test-cockpit-terminal-xss.sh` prouve qu'une charge dans P ne fait créer aucun fichier marqueur par le shell (TERM-12).

**Recommandation principale :** le bouton reste dans P et ne fait que *proposer*. Le serveur P ne compose la commande qu'à partir d'identifiants validés par motif, jamais de texte du lab. Il la passe à Q par l'IPC serveur → enfant, qui existe déjà. La *confirmation* (« Lancer / Annuler ») se fait dans Q, sur le modèle du bandeau de collage. Q écrit au PTY seulement si le premier plan du terminal est le shell, ce que l'assistant Python sait mesurer avec `tcgetpgrp`. Sans `--terminal`, il reste un repli « Copier la commande » qui n'ouvre aucun canal.

Contraintes héritées, non négociables : le lab observé n'est jamais une source de code, et aucun secret ne part vers le SSE, le journal ou l'export [VERIFIED: 71-CONTEXT.md:188-193]. Sans `--terminal`, la CSP de page reste octet pour octet celle de `v2.75.0` (TERM-01) [VERIFIED: 71-CONTEXT.md:207-208]. Le head ne se voit jamais prescrire une commande `gsd-*` [VERIFIED: plugin/dev-orchestrator/references/head-governance.md:9-12].

## Architectural Responsibility Map

| Capacité | Tier principal | Tier secondaire | Motif |
|---|---|---|---|
| Bouton « Lancer » sur une carte | Navigateur, page P | — | Le viewer expose `addPanelSection('item', fn)` (§1) |
| Pré-vol (dépendances, verrous, worktree, outils) | Serveur P (`vf-cockpit-server.mjs`) | Enfant Q (état du PTY) | P a déjà le graphe, les verrous et les arbres ; Q seul connaît le premier plan du PTY |
| Composition de la ligne de commande | Serveur P (gabarit + identifiants validés) | Assistant PTY (revalidation) | Jamais le navigateur, jamais du texte du lab |
| Confirmation humaine | Navigateur, page Q (origine distincte) | — | P compromise ne peut ni lire ni piloter Q (P71-D-13, T-71-41) |
| Écriture au PTY | Enfant Q → `vf-cockpit-pty.py` | — | Le test du premier plan doit être atomique dans la boucle de l'assistant |

---

## 1. Inventaire des cartes du cockpit

**Onglet Projet (`project.html`)**, graphe construit par `buildProjectGraph` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-project.mjs:27-129].

| Carte | Identifiant (verbatim) | Données portées | Source |
|---|---|---|---|
| Jalon | `id: ms.id` (`'ms-' + key…`), `kind: 'jalon'` | `st`, `foot` (« N clos · … · N % »), `tags` compartiment | project.mjs:66-67 ; planning.mjs:75 |
| Phase | `` `ph-${ph.n}@${ph.ws}` `` si le numéro existe dans deux compartiments, sinon `` `ph-${ph.n}` `` ; `kind: 'phase', num: ph.n, ws: ph.ws` | `summary` (Goal), `details` (Reste, worktree « ailleurs », mission, « Dépend de : Phase … », ligne de ROADMAP, source et dossier), `st`, `foot` (« à recetter · N/M plans · N correctifs · N/M exigences · dans worktree X »), `paths: [dossier]` | project.mjs:41, 81-83 |
| Plan (élément) | `f:<chemin du PLAN.md>` | `st` (`done` si SUMMARY), `foot` « vague N · N fichiers », `touched` (`files_modified`) | project.mjs:84-91 |
| Exigences | `` `${id}.req` `` puis `f:req/<ws>/<ID>` | cochée ou non | project.mjs:93-95 |
| Mission | `'dag-' + d.name`, `kind: 'mission'`, enfant de la phase (sinon de « Missions hors phase ») | `st`, `foot` « N/M nœuds », `paths: [d.file]` | project.mjs:102-108 |
| Nœud de mission | `` `${d.file}#${x.id}` `` | `st` = `DST[x.status]`, `stage`, `scope` | project.mjs:109-110 |
| Backlog, Graines, Releases | `backlog`, `seeds`, `releases` | entrées | project.mjs:115-125 |

**L'avancement d'une phase** est un objet versionné, en v2 : `{ version: 2, etat, plans: { faits, total }, correctifs, mission: { nom, etat, vie } | null, reste: [codes] }` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-avancement.mjs:3-4]. Valeurs exactes : `ETATS = ['a-faire', 'en-cours', 'a-recetter', 'fait']`, `RESTE = ['recette', 'verification', 'cloture']` [VERIFIED: avancement.mjs:11-12]. Les dépendances sont lues dans la prose `**Depends on:**` du ROADMAP par une heuristique : parenthèses retirées, identifiants `X-D-n` retirés, coupe à la première phrase, puis tous les nombres `\b(\d+(?:\.\d+)?)\b` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-planning.mjs:49-54]. Elles sont donc **indicatives, jamais certaines**. Le numéro de phase vient toujours du motif `NUM = '(\\d+(?:\\.\\d+)?)'` [VERIFIED: planning.mjs:27]. Il est sûr par construction. Le compartiment, lui, est un **nom de dossier quelconque** pris sous `.planning/workstreams/` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-paths.mjs:31-33]. Il doit être validé avant tout usage dans une commande.

**Onglet Équipe (`equipe.html`)**, construit en mémoire à chaque appel [VERIFIED: plugin/cockpit/scripts/vf-cockpit-server.mjs:127-134]. Cartes `(w.kind === 'session' ? 'se-' : 'ag-') + w.id` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-equipe-carte.mjs:13], `kind: sous ? 'agent' : 'session'`. Le `details` donne rôle, état, branche, arbre et « Nœud de mission » quand l'agent est rattaché [VERIFIED: equipe-carte.mjs:27-35]. Ce sont des sessions **déjà en cours ou finies** : on n'y « lance » rien, on pourrait au plus *reprendre* (voir zone grise Z6). L'identifiant passe par `ID_RE = /^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$/` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-lecture.mjs:65].

**Points d'accroche dans le viewer :**
- `addPanelSection(where, fn) { (ext.sections[where] ||= []).push(fn); }` [VERIFIED: plugin/cockpit/skills/cockpit-moteur/assets/viewer.html:2371]. Le panneau d'un élément appelle chaque section avec l'identifiant sélectionné. `{ top: true }` place la section juste sous l'en-tête [VERIFIED: viewer.html:1521-1546]. C'est déjà le motif de `00-vibeflow.js:132-145`, `70-vf-live.js:173` et `72-vf-equipe.js:149`.
- Le menu contextuel des cartes passe par `itemMenu(id)` [VERIFIED: viewer.html:1118, 1200-1206]. C'est une fonction interne du viewer, non exposée par `window.Floorplan`. Un « Lancer » dans le clic droit demanderait un patch du viewer vendorisé (patch amont, `amont/SYNCHRO.md`) : à éviter.
- Dans la sortie assemblée, l'API s'appelle `window.VibeFlow`, l'en-tête de jeton `x-vf-cockpit-token` et la globale serveur `VF_COCKPIT_SERVER`. Ce renommage est mécanique [VERIFIED: plugin/cockpit/scripts/vf-cockpit-rename.mjs:15-18].
- **Contrainte TERM-01** : un script de plus dans `assets/ui/` ajouterait une empreinte à la CSP même sans `--terminal`. La 71 a donc fait servir le tiroir à la volée, seulement avec le drapeau [VERIFIED: 71-CONTEXT.md:113-117 (P71-D-20)]. L'interface de lancement doit suivre la même voie : injectée par `TERM.injection()`, que `inject` concatène [VERIFIED: serve.mjs:174], ou par un sibling chargé de la même façon.
- Le tiroir ne se monte que sur `['/', '/index.html', '/project.html']` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-terminal-tiroir.mjs:30]. **Il est absent de `equipe.html`.** Un lancement depuis l'onglet Équipe suppose soit d'y monter le tiroir, soit d'envoyer l'utilisateur vers Projet.

## 2. Le chat actuel

- **Fichiers :** `vf-cockpit-ask.mjs` fournit `answerLocally(G, question)`, qui calcule des réponses sans modèle, et `instructions(G)`, la consigne de l'agent [VERIFIED: plugin/cockpit/scripts/vf-cockpit-ask.mjs:1-8, 32, 124-137]. La route est `POST /api/ask` dans `serve.mjs`, corps limité à 20 000 octets [VERIFIED: serve.mjs:564-568]. Le crochet `avantQuestion` répond localement quand une forme connue suffit [VERIFIED: vf-cockpit-server.mjs:107-119].
- **Il appelle bien `claude -p` côté serveur :** `[...cli.args, '-p', '--output-format', 'stream-json', '--verbose', '--json-schema', …, '--append-system-prompt', mode.instructions, …]`, lancé par `spawn(cli.cmd, run.args, { cwd: root, env: cliEnv(), … })`. La question arrive par stdin [VERIFIED: serve.mjs:276-283, 327-331].
- **Droits d'outils :** les arguments amont sont remplacés par `ARGS_CONFINEMENT` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-agent.mjs:14-20, 40-49] :
  ```
  '--permission-mode', 'dontAsk',
  '--tools', 'Read,Grep,Glob,Bash',
  '--allowedTools', 'Bash(node .vibeflow/cockpit/query.mjs:*)', 'Bash(node .vibeflow/cockpit/vf-cockpit-query.mjs:*)', 'Read(./**)', 'Grep(./**)', 'Glob(./**)',
  '--setting-sources', '',
  '--strict-mcp-config',
  ```
  Modèle dans une liste fermée : `MODELES = ['sonnet', 'opus', 'haiku']` [VERIFIED: agent.mjs:11]. Le chat est en lecture seule, sans hooks ni réglages ni MCP. **Il ne peut rien lancer**, et c'est voulu.
- **Où vit la conversation :** en mémoire dans le navigateur, `askState = { …, session: null, … }`, et le `session` rendu par l'agent est renvoyé à la question suivante [VERIFIED: viewer.html:1908, 2105, 2119]. Côté serveur, la suite reprend la session par `--resume=<uuid>`, seulement si `/^[0-9a-f-]{36}$/i` [VERIFIED: serve.mjs:280]. Puisque `--resume` fonctionne, la session est persistée par Claude Code dans ses transcripts du compte. Aucun `--no-session-persistence` n'est passé. Le contexte de la carte vient d'`addAskContext(id)` : trois cartes au plus en « puces » [VERIFIED: viewer.html:2151-2156].
- **En tirer un contexte de lancement :** il y a deux voies réalistes.
  1. Le contexte, c'est la carte : l'identifiant de phase ou de mission suffit, l'agent lancé relira le ROADMAP et le CONTEXT lui-même.
  2. Reprendre la conversation du chat : `claude -r <uuid> --fork-session` dans le terminal, qui crée une nouvelle session à partir de l'historique. `--fork-session` existe [VERIFIED: `claude --help`, 2.1.318]. D'après la doc, `--resume <id>` cherche dans le projet courant et ses worktrees, puis dans tous les autres projets [CITED: code.claude.com/docs/en/cli-reference, ligne `--resume`]. Cela couvre l'écart de slug entre `cwd: root`, non résolu (serve.mjs:327), et `cwd: fs.realpathSync(lab)` côté terminal [VERIFIED: plugin/cockpit/scripts/vf-cockpit-terminal-session.mjs:89]. Que la session reprise retrouve tous ses outils (et non le confinement du chat) n'est pas vérifié [ASSUMED].
- **Fait d'interface :** quand le tiroir est ouvert, la barre de question disparaît : `body.vf-term-ouvert #ask { display: none; }` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-terminal-tiroir-style.mjs:46] (P71-D-35, G1). Aujourd'hui, le chat et le terminal ne sont pas visibles ensemble.

## 3. Le terminal Q : chemin d'une entrée, session, premier plan

**Chemin d'une frappe** : xterm.js dans la page Q → `term.onData` → `POST /entree` (en-têtes `X-VF-Terminal` = secret, `X-VF-Onglet`) → `controle()` → `sessions.ecrire()` → stdin de l'assistant → maître du PTY.
- Contrôles de Q : méthode GET ou POST, puis Host exact `127.0.0.1:Q` (`localhost:Q` seulement pour `GET /`), puis Origin exacte de Q. Pour `GET /flux` et `GET /etat` seulement, l'absence d'Origin est admise si `sec-fetch-site === 'same-origin'` et que le secret est valide [VERIFIED: plugin/cockpit/scripts/vf-cockpit-terminal-processus.mjs:48-59] (P71-D-24). Vient ensuite le secret en temps constant [VERIFIED: processus.mjs:90]. Les routes sont une liste fermée : `{ '/amorce': 'POST', '/flux': 'GET', '/entree': 'POST', '/taille': 'POST', '/etat': 'GET' }` [VERIFIED: processus.mjs:91]. Corps d'entrée borné : `CORPS_ENTREE_MAX = 65536` [VERIFIED: processus.mjs:18].
- Côté client, seule une entrée **humaine** part pendant le rejeu du tampon (`partir = (b) => { if (rejeu && !humain) return; … }`) [VERIFIED: plugin/cockpit/scripts/vf-cockpit-terminal-client.mjs:143-156].
- **Session** : une seule. Un autre onglet reçoit `409`, une session en fermeture `503` ; grâce `GRACE_MS` de 30 000 ms ; tampon `TAMPON_MAX = 262144` octets, en mémoire seulement [VERIFIED: terminal-session.mjs:19, 27-29, 118-131]. L'état exposé est `{ session, code, signal }` [VERIFIED: terminal-session.mjs:146].
- **Q ne lit aucun paramètre d'adresse en dehors du thème** : `url.searchParams.get('theme') === 'light' ? 'light' : 'dark'` [VERIFIED: processus.mjs:82]. Le cadre est chargé par `origineQ + '/?theme=' + theme()` [VERIFIED: tiroir.mjs:105]. En-tête de `vf-cockpit-terminal-page.mjs` : « Aucun autre paramètre d'adresse n'est lu (P71-D-15) » [VERIFIED: plugin/cockpit/scripts/vf-cockpit-terminal-page.mjs:7].
- **Canal Q → P** : uniquement des valeurs fixes, `LISTE_MESSAGES = ['ready', 'etat:connecte', 'etat:reconnexion', 'etat:termine', 'etat:refuse', 'etat:expire', 'etat:arrete', 'toggle']` [VERIFIED: tiroir.mjs:8]. Le filtre `accepteMessage` exige `isTrusted`, une origine exacte, la source = le cadre et une valeur de la liste [VERIFIED: tiroir.mjs:21-26].
- **Canal serveur P → enfant Q (IPC de `fork`), qui existe déjà :** « parent -> enfant : { t:'init', engineDir, root, here, jetons, portP, envOrigine } · { t:'jetons', jetons } · { t:'arret' } / enfant -> parent : { t:'pret', port } · { t:'occupe', v } · { t:'echec', code } » [VERIFIED: processus.mjs:4-5, 139-144 ; plugin/cockpit/scripts/vf-cockpit-terminal.mjs:55-76]. La décision P71-D-15 porte sur le **navigateur** : `postMessage` et l'URL du cadre. Ajouter un message IPC `{ t:'proposition', … }` n'ouvre pas le sens P → Q au sens de P71-D-15. Cela crée en revanche un **nouveau chemin pour qu'une charge exécutée dans P fasse naître une proposition**. La garde, c'est la confirmation dans Q, et la décision appartient à Samuel (Z1).

**Premier plan du PTY : mesuré.** L'assistant lit déjà `os.tcgetpgrp(maitre)` dans `groupes()` [VERIFIED: plugin/cockpit/skills/cockpit-moteur/terminal/vf-cockpit-pty.py:111-118]. Le shell est lancé par `os.execvp(shell, [shell, '-l'])` dans `pty.fork()`, chef de sa session [VERIFIED: vf-cockpit-pty.py:394-397]. La sonde de cette session (`scratchpad/research72/pgrp.py`, macOS, Python 3.14.6, HOME jetable) a donné :
```
/bin/zsh repos: shell pid 18442 pgid 18442 tcgetpgrp(master) 18442 repos= True
/bin/zsh sleep: tcgetpgrp(master) 22654 repos= False
/bin/zsh apres: tcgetpgrp(master) 18442 repos= True
/bin/bash repos: shell pid 33608 pgid 33608 tcgetpgrp(master) 33608 repos= True
/bin/bash sleep: tcgetpgrp(master) 37397 repos= False
/bin/bash apres: tcgetpgrp(master) 33608 repos= True
```
`tcgetpgrp(maître) == pid du shell` distingue donc de façon fiable « shell au repos » de « programme au premier plan », sur macOS, pour zsh et bash [VERIFIED: sonde ci-dessus]. Ni Linux ni fish n'ont été sondés [ASSUMED : même comportement, `tcgetpgrp` étant POSIX]. **Limites :** « shell au premier plan » ne veut pas dire « ligne vide », car du texte peut être tapé en attente ; un `precmd` synchrone (prompt git) peut faire basculer brièvement le premier plan.

**Où insérer le lancement sans rouvrir le sens P → Q du navigateur :**
- *Recommandé :* passer par l'IPC serveur. Q annonce une proposition en attente dans `GET /etat`, que le client lit déjà, ou dans un nouveau `GET /proposition`. La page Q affiche un bandeau de confirmation, sur le modèle de `vue.collage(texte, coller, annuler)` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-terminal-vue.mjs:78-114]. Un nouveau `POST /lancer` dans Q, avec Origin de Q, secret et onglet, déclenche l'écriture. Une nouvelle ligne de contrôle sur le fd 3 de l'assistant (aujourd'hui seul `R <l> <c>` est reconnu [VERIFIED: vf-cockpit-pty.py:99-108]) permet de « vérifier le premier plan puis écrire » d'un seul tenant. Ajouter une ligne d'état sur le fd 2, par exemple `PP 1`, est sans risque : le parseur actuel n'accepte que `/^(FIN|SIG) (\d{1,3})$/` et ignore le reste [VERIFIED: terminal-session.mjs:101-109].
- *Écarté :* un paramètre d'URL du cadre (`?lancer=…`). P71-D-15 l'interdit à la lettre (« aucune configuration sensible dans son URL hors amorçage », 71-CONTEXT.md:89). Le cadre se recharge et rejoue le tampon (P71-D-19), alors que des réponses d'identification réinjectées au rejeu ont déjà été un défaut (R1, P71-D-36). Il n'offre aucun gain de sécurité face à une charge dans P, qui peut aussi changer l'adresse du cadre.
- *Écarté :* le `postMessage` P → Q (P71-D-15, T-71-34 : « aucun écouteur de message dans Q »).

## 4. Pré-vols possibles sans exécuter de script du lab

| Contrôle | Déjà calculé ? | Où | Note |
|---|---|---|---|
| Phase existante, compartiment, identité unique | oui | `phId` project.mjs:41 ; `trouverPhase` avancement.mjs:39-43 | Ambiguïté entre compartiments déjà gérée par le chat (ask.mjs:54-56) |
| État de la phase (`fait` = impossible ; `a-recetter` = recette, pas exécution) | oui | `avancement()` avancement.mjs:96-101 | `reste` dit ce qui manque : `recette`, `verification`, `cloture` |
| Dépendances non closes | oui (heuristique) | `ph.depends` planning.mjs:49-54 ; liens « dépend de » project.mjs:98 | Avertir, ne pas bloquer : l'analyse de prose peut se tromper |
| CONTEXT, PLAN, SUMMARY présents (étape suivante) | en partie | `decompte()` avancement.mjs:25-35 compte PLAN et SUMMARY ; **CONTEXT et RESEARCH ne sont pas lus** | Il faut ajouter « CONTEXT présent ? », à lire sur la liste du dossier déjà faite (`ls(dir)`, project.mjs:76) |
| Mission vivante sur la phase (verrou tenu ou progrès récent) | oui | `lireVerrous` puis `vieDe`, `estVivante` [VERIFIED: plugin/cockpit/scripts/vf-cockpit-vie.mjs:27-31, 36-51, 58-71] | Lecture par `bash <driver-lock.sh> status --all`, script résolu dans le **module** et refusé s'il est sous `<lab>/.vibeflow` ou sous le lab [VERIFIED: paths.mjs:69-84] : ce n'est pas un script du lab |
| Format des verrous | — | `<git-common-dir>/vf-driver/{ws/<sujet>,repo}/DRIVER.lock`, verrou de phase `…/ws/<sujet>/phases/<N>/DRIVER.lock`, hors git `.planning/DRIVER.lock.d/…` [VERIFIED: plugin/conductor/scripts/driver-lock.sh:52, 74-75, 94-96, 387-401] | Le cockpit ne lit **jamais** ces fichiers directement, toujours par `status --all` (JSON) : garder ce passage |
| Phase plus avancée dans un autre worktree | oui | `lireAilleurs` / `fusionner` (vf-cockpit-ailleurs.mjs:1-11) ; `details` « Avancement lu dans le worktree … » (project.mjs:82) | Signal fort : « la phase vit ailleurs, ne lance pas ici » |
| Worktrees et branches, phase active par branche | oui | `arbresGit`, `phaseActive` (motif `phase-(\d+(?:\.\d+)?)`) [VERIFIED: plugin/cockpit/scripts/vf-cockpit-arbres.mjs:24-34, 59-66] ; agrégé par `collectSignal` (vf-cockpit-signal.mjs:36-79) | git toujours appelé avec `GIT_SUR = ['--no-optional-locks', '-c', 'core.fsmonitor=false']` [VERIFIED: paths.mjs:125] |
| Arbre sale (non commité) | **non, et c'est délibéré** | En-tête d'arbres.mjs : « sous-commandes qui ne lisent ni l'index ni l'arbre de travail » [VERIFIED: arbres.mjs:6] | `git status` lit l'index et l'arbre de travail. Il peut déclencher des filtres configurés dans le `.git/config` du lab [ASSUMED]. L'ajouter contredit T-68-04 : décision de Samuel (Z5). Recoupe la Phase 73 (« travail non commité », réservée) |
| `claude` présent | oui, **pour le serveur** | `cli` résolu par `which` sous le PATH assaini ; `version` par `--version` [VERIFIED: serve.mjs:95-100, 168] ; `GET /api/health` → `{ cli: !!cli, engine, want, version, path }` [VERIFIED: serve.mjs:525] | Le shell garde le PATH **d'origine** (P71-D-03 ; `VF_COCKPIT_PATH_ORIGINE`, terminal-env.mjs:22-25). « Présent pour le serveur » ne prouve pas « présent dans le shell ». Le seul juge fiable est le lancement lui-même |
| `python3` présent | oui | `resoudrePython3` (terminal-session.mjs:33-40) ; `/etat` → `{ etat: 'indisponible', raison: 'python3-absent' }` (processus.mjs:97) | |
| Terminal actif, session vivante | oui | `GET /api/vf/terminal` → `{ etat: 'actif', port }` / `{ etat: 'arrete' }` (vf-cockpit-terminal.mjs:51) ; `occupe` par IPC (terminal.mjs:59) | P sait « il y a une session », pas « elle est au repos » : il manque le premier plan (§3) |
| Premier plan du PTY = shell | **non** | à ajouter dans l'assistant (`tcgetpgrp`, mesuré en §3) | Indispensable avant d'écrire une ligne |
| Lancement en cours ailleurs (deux clics) | non | à ajouter : une seule proposition en attente à la fois dans Q | |

## 5. La commande lancée

**CLI vérifiée** (`claude --help`, 2.1.318, et référence officielle) :
- `Usage: claude [options] [command] [prompt]`. `claude "query"` démarre une session interactive avec un prompt initial [VERIFIED: `claude --help` ; CITED: code.claude.com/docs/en/cli-reference, table « CLI commands »].
- `-n, --name <name>` : nom affiché dans `/resume` et le titre du terminal ; on peut reprendre par `claude --resume <name>` [CITED: cli-reference, ligne `--name`].
- `--permission-mode` accepte `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions`, et `manual` comme alias de `default`. Le drapeau remplace le `defaultMode` des réglages [CITED: cli-reference, ligne `--permission-mode`]. Aide locale : `choices: "acceptEdits", "auto", "bypassPermissions", "manual", "dontAsk", "plan"` [VERIFIED: `claude --help`].
- `--append-system-prompt <prompt>` et `--append-system-prompt-file <fichier>` [CITED: cli-reference, lignes 70-71].
- `--session-id <uuid>` (« must be a valid UUID »), `-w, --worktree [name]` (crée `<repo>/.claude/worktrees/<name>`), `--agent <agent>`, `--fork-session`, `-r, --resume` [VERIFIED: `claude --help` ; CITED: cli-reference].
- **Non vérifié :** qu'un skill passé en prompt initial (`claude '/vf-dev …'`) se déclenche comme une commande. Aucune source officielle ne le dit ; des guides tiers disent seulement qu'une commande slash est reconnue en début de message [ASSUMED]. À sonder en vague 0 avec un skill témoin.
- **Non vérifié :** `claude --agent vibeflow-head` comme forme « incarnée » du head (B1, head-governance.md:14-19), ni le nom sous lequel l'agent du plugin est exposé (namespacé ou non) [ASSUMED]. L'agent est défini par `name: vibeflow-head`, `model: opus` [VERIFIED: plugin/dev-orchestrator/AGENT.md:1-6].

**Ce qu'attend le head :** une intention en langage naturel. `vf-dev` « Incarne l'agent `vibeflow-head` — jamais dispatché en Task », lance `Task(vf-coder)` ou `Task(vf-dev-manager)`, « jamais un skill `gsd-*` en direct » [VERIFIED: plugin/dev-orchestrator/skills/vf-dev/SKILL.md:9-14]. La mémoire du dépôt pose la même règle : ne jamais prescrire de commande `gsd-*` dans un brief au head. Le prompt doit donc *nommer la cible et l'intention*, par exemple « Avance la Phase 72 du compartiment fiabilite ». Il ne doit jamais nommer le geste GSD (`/gsd-plan-phase 72`).

**Composer sans jamais interpoler de texte du lab :**
1. *Gabarit fermé.* La ligne est un gabarit constant. Ses seules variables sont des identifiants validés :
   - numéro de phase : `^\d+(?:\.\d+)?$`, motif du parseur ;
   - compartiment : par exemple `^[a-z0-9][a-z0-9-]{0,39}$`, à fixer. Un nom de dossier hors motif = lancement refusé et le dire, jamais un nom « nettoyé » ;
   - verbe d'intention : pris dans une liste fermée, par exemple `avance`, `recette`, `reprends` ;
   - nom de session : construit à partir de ces seuls champs.
   **Jamais** le titre de phase, le Goal, un nom de mission ou de nœud (ces trois-là sont du texte du lab ; `ID_RE` les borne, mais ils n'ont rien à faire dans une commande).
2. *Guillemets simples et alphabet fermé.* Chaque argument est entre guillemets simples et la ligne entière vérifie un alphabet fermé (par exemple `^[A-Za-z0-9 ._:/'-]+$`, sans `'` à l'intérieur d'un argument). Les guillemets simples sont littéraux pour sh, bash, zsh et fish : pas de `$`, pas d'accent grave, pas de développement d'historique `!`, alors que bash interactif développe `!` entre guillemets doubles [ASSUMED : sémantique POSIX et fish connue, non sondée cette session]. Le shell peut être n'importe lequel (`choisirShell`, terminal-env.mjs:35-39). La revalidation se fait à deux endroits : le serveur P compose, l'assistant Python revalide l'alphabet avant d'écrire.
3. *Contexte riche par fichier, pas par la ligne.* Ce qui ne passe pas l'alphabet va dans un fichier écrit par le serveur, par exemple `.vibeflow/cockpit/.cache/lancement-<uuid>.md` en 0600 et création exclusive, sur le modèle de l'amorçage (P71-D-21, O3). On le désigne par `--append-system-prompt-file '<chemin constant>'`. Le contenu atteint le modèle comme une donnée, jamais le shell. Le risque d'injection de prompt reste celui de tout travail dans un lab hostile (limite de fond, 71-CONTEXT.md:195-199).
4. *Pas d'Entrée envoyée par défaut.* La ligne arrive au shell **sans `\r`** ; l'utilisateur la voit à l'invite et appuie lui-même sur Entrée. C'est une seconde confirmation, une vraie frappe dans l'origine Q. Pour vider une ligne en attente, `\x03` (Ctrl-C) en tête est plus portable que `^A^K` ou `^U`, qui dépendent du mode emacs ou vi. Ctrl-C n'est envoyé **que si** le premier plan est le shell, sinon il tuerait le programme en cours.
5. `--session-id <uuid>` généré par le serveur : le cockpit retrouve la session lancée dans l'onglet Équipe (`~/.claude/projects/<slug>/<uuid>.jsonl`, lu par `vf-cockpit-who.mjs`, P69-D-22) et peut la rattacher à la carte. Un UUID n'est pas un secret.
6. Variante sans shell (Z3) : quand **aucune** session n'existe, l'assistant peut lancer le programme directement. Aujourd'hui `execvp(shell, [shell, '-l'])` (pty.py:397) ; la variante serait `execvp('claude', [argv…])`, sans aucune analyse shell, donc sans injection possible. Coût : à la sortie de `claude` la session se termine, et l'environnement de connexion du shell n'est pas rejoué.

Exemple, à valider au cadrage :
```
claude --session-id '1b9d…-uuid' -n 'vf-phase-72-fiabilite' --append-system-prompt-file '.vibeflow/cockpit/.cache/lancement-1b9d….md' 'Avance la Phase 72 du compartiment fiabilite'
```
Tous les éléments variables viennent des motifs ci-dessus ; le reste est constant. Que le chemin du fichier reste relatif au `cwd` du shell suppose que l'utilisateur n'a pas fait `cd`. Il faut soit un chemin absolu (le chemin du lab est du texte du système de fichiers, à valider par l'alphabet ou à refuser), soit le test `cwd du shell == lab`, faisable par `os.readlink('/proc/<pid>/cwd')` sous Linux et `lsof` sous macOS [ASSUMED].

## 6. Recoupement de périmètre

Mesures prises par `rtk proxy git …` depuis ce worktree, le 2026-11-05.

| Branche | Avance sur `origin/main` | Fichiers touchés |
|---|---|---|
| `feat/phase-71-5-unslop-espacements` | **0 commit** (pointe sur `aff9f260`) | aucun commité. Phase 71.5 inscrite dans aucun ROADMAP commité (`git grep "71\.5"` vide). Le travail non commité de son worktree n'a pas été lu (mandat : lecture dans ce worktree seulement) |
| `feat/phase-78-git-cockpit` | 1 commit `4d185446` | `.planning/workstreams/fiabilite/ROADMAP.md` seul (+15). Elle se déclare « En parallèle de la 72 » et nomme des recoupements avec les Phases 73 (« worktrees, branches et travail non commité ») et 75 (« données tirées de `git log` »), et avec la 71.5 (espacements) |
| `chore/cloture-71-inversion-terminal` (= `origin`, `3d1bfe23`) | 3 commits, **non mergée** | `plugin/cockpit/VERSION` (`v1.3.2` → `v1.3.3`), `module.json`, `CHANGELOG.md`, `README.md`, `scripts/vf-cockpit-terminal-tiroir.mjs` (+19/−4 : `eviter()` inversé), `scripts/vf-cockpit-terminal-tiroir-style.mjs`, `tests/test-cockpit-terminal-tiroir.sh`, plus REQUIREMENTS, ROADMAP, STATE et 71-RECETTE |
| `docs/jalon-v2-phases-73-77` | contenu 73-77 **absent des commits** (`git grep "Phase 7[3-7]"` vide) | non commité dans son worktree, non lu |

**Fichiers que la 72 devrait toucher** (estimation) :
- `vf-cockpit-terminal-processus.mjs` (IPC `proposition`, routes `/lancer` ou `/proposition`) ;
- `vf-cockpit-terminal-session.mjs` (écriture conditionnée) ;
- `vf-cockpit-pty.py` (premier plan, ligne de contrôle) ;
- `vf-cockpit-terminal-client.mjs` et `-vue.mjs` (bandeau de confirmation) ;
- `vf-cockpit-terminal.mjs` (relais IPC) ;
- `vf-cockpit-server.mjs` : la route n'admet aujourd'hui **que GET**, `if (req.method !== 'GET') { res.writeHead(405); … }` [VERIFIED: vf-cockpit-server.mjs:70]. Un `POST /api/vf/lancer` change cette ligne ;
- un nouveau fichier d'interface injecté sous `--terminal` (section du panneau de carte) ;
- un nouveau module pur `vf-cockpit-lancement.mjs` (gabarit, motifs, pré-vol) ;
- les suites `test-cockpit-terminal-*.sh` et une suite neuve ;
- `VERSION`, `CHANGELOG.md`, `README.md`, `module.json`.

**Recouvrements signalés :**
1. **La clôture de la 71 n'est pas sur main** et touche `vf-cockpit-terminal-tiroir.mjs` et `VERSION`. La 72 doit repartir de `main` *après* son merge (ou rebaser). Sinon, conflit certain sur le tiroir et sur la version.
2. **78** : vraisemblablement `vf-cockpit-server.mjs` (routes Git), `vf-cockpit-arbres.mjs`, l'en-tête du viewer et `00-vibeflow.js`. La 72 ne devrait ajouter qu'une route à `vf-cockpit-server.mjs` et lire `arbres` sans le modifier. Le contrôle « arbre sale » de la 72 et le « travail non commité » de la 73 se recoupent sur le **même calcul** : il doit vivre en un seul endroit, à trancher entre 72, 73 et 78.
3. **71.5** : `vf-cockpit-terminal-tiroir-style.mjs`, `vf-cockpit-terminal-style.mjs`, les jetons d'espacement du viewer. Le bandeau de confirmation de la 72 doit **réutiliser** les classes `vf-q-bandeau` et `vf-q-collage` (vue.mjs:68, 101) sans créer de jeton d'espacement.
4. Fichiers de version et docs du module : conflit garanti entre trois phases parallèles ; à recenser comme la 71 l'a fait (`71-BRANCHEMENTS-MERGE.md`, P71-D-17).

## 7. Harnais de test

- `chrome-session.mjs` : un Chrome headless par exécution, CDP sans dépendance, échéances bornées, erreurs nommées [VERIFIED: plugin/cockpit/scripts/tests/chrome-session.mjs:1-5, 16-22]. Il sait taper des touches de confiance par `Input.dispatchKeyEvent` (`chrome-equipe-clavier.mjs:40-41`). Chrome est présent sur le poste (`/Applications/Google Chrome.app`).
- `terminal-aux.mjs` : client Node des routes de Q (`req <port> <METHODE> <chemin> --origin --secret --onglet …`) [VERIFIED: plugin/cockpit/scripts/tests/terminal-aux.mjs:1-6].
- `test-cockpit-terminal-xss.sh` : chaîne « P compromise → Q → shell », succès = fichier marqueur **créé par le shell**, témoin C0t (Q privée de ses contrôles → la chaîne aboutit), et mode simulé sans Chrome [VERIFIED: tests/test-cockpit-terminal-xss.sh:1-14]. C'est la suite à étendre en premier.
- `test-cockpit-terminal-pty.sh` : programme témoin plein écran (`temoins/plein-ecran.py`, T13) [VERIFIED: tests/test-cockpit-terminal-pty.sh:27, 371-373]. Il sert de modèle pour un « faux `claude` ».
- `test-cockpit-terminal-lanceur.sh` : faux binaires dans `fauxbin/`, PATH piégés `.:…`, `:…`, `bin:…` [VERIFIED: tests/test-cockpit-terminal-lanceur.sh:21, 48, 290].

**Bout en bout avec un faux `claude` :**
1. Lab fixture. Une phase dont le **titre** vaut `$(touch "$WORK/run/pwn")'"!x`, un compartiment conforme et un compartiment au nom de dossier hostile, par exemple `a$(id)`.
2. Faux `claude`, premier dans le PATH **d'origine** que le shell reçoit (le lanceur le conserve dans `VF_COCKPIT_PATH_ORIGINE`). Il écrit ses arguments séparés par NUL dans `$WORK/run/argv` puis sort.
3. Serveur `--terminal`, session légitime par `terminal-aux.mjs` (onglet A), proposition par `POST /api/vf/lancer` avec le jeton de P, confirmation par `POST /lancer` dans Q (Origin Q, secret, onglet), puis la frappe `\r`.
4. Assertions :
   - `argv` = tableau attendu, octet pour octet ;
   - aucun `pwn` ;
   - compartiment hostile → refus et aucun argv ;
   - proposition sans confirmation → aucun argv ;
   - programme au premier plan (`sleep 30`) → refus et le `sleep` vit toujours (aucun `\x03` envoyé).
5. Variante navigateur. Clic sur « Lancer » dans le cadre Q par `Input.dispatchMouseEvent`, après focus du cadre. Puis charge XSS dans P (mutants M-ESC et M-CSP repris de `test-cockpit-chaine-xss.sh`) qui appelle `/api/vf/lancer` : une proposition apparaît dans Q, mais **aucun argv sans geste dans Q**.

**Mutants à prévoir**, chacun doit rougir au moins une assertion :
- M-INTERPOLE : le gabarit insère le titre de phase ;
- M-MOTIF-WS : motif de compartiment relâché ;
- M-SANS-CONFIRM : Q écrit dès la proposition ;
- M-PREMIER-PLAN : le test `tcgetpgrp` est sauté ;
- M-CTRLC-AVEUGLE : `\x03` envoyé sans test du premier plan ;
- M-ORIGINE-LANCER : `/lancer` accepte l'Origin de P ;
- M-ENTREE-AUTO : `\r` ajouté par Q ;
- M-ALPHABET-PY : l'assistant ne revalide pas.

Le dépôt a pour règle que toute preuve doit pouvoir rendre rouge : chaque mutant se joue avant le code, comme la 71 l'a fait avec ses `*-RED-TRACE.md`.

**Validation (Nyquist, activée : `workflow.nyquist_validation: true` dans `.planning/config.json`) :**

| Comportement | Type | Commande | Existe ? |
|---|---|---|---|
| Gabarit, motifs, alphabet (module pur) | unitaire | `node --test` ou suite shell neuve `test-cockpit-lancement.sh` | ❌ vague 0 |
| Premier plan mesuré par l'assistant | intégration PTY | ajout à `test-cockpit-terminal-pty.sh` | ❌ |
| Proposition, confirmation, écriture (HTTP) | intégration | ajout à `test-cockpit-terminal-serveur.sh` ou suite neuve | ❌ |
| Chaîne XSS jusqu'au lancement | navigateur et simulé | extension de `test-cockpit-terminal-xss.sh` | ❌ (suite existante) |
| TERM-01 : CSP identique sans `--terminal` | non-régression | `test-cockpit-terminal-activation.sh` | ✅ |
| Skill en prompt initial, `--agent vibeflow-head` | sonde (spike) | vrai `claude`, skill témoin, lab jetable | ❌ vague 0, manuel |

Gate de phase : rejouer les commandes du job CI `gates` de `.github/workflows/ci.yml`, jamais une liste recopiée (règle du dépôt).

## Sécurité (ASVS niveau 1, `security_enforcement: true`)

| Menace | STRIDE | Contrôle recommandé |
|---|---|---|
| Une charge dans P déclenche un lancement | Élévation | Proposition seule depuis P ; confirmation dans Q (origine distincte, secret inaccessible depuis P, T-71-41) ; aucune Entrée automatique |
| Injection shell par un texte du lab | Altération | Gabarit fermé et identifiants par motif, revalidés dans l'assistant ; alphabet fermé ; mutants M-INTERPOLE et M-MOTIF-WS |
| Détournement de clic : P rend le cadre Q invisible et attire le clic sur « Lancer » | Usurpation | P encadre Q et contrôle son CSS : la 71 n'a pas étudié ce cas (aucune occurrence de « clickjack » dans 71-SECURITY.md ni 71-RESEARCH.md, mesuré). Parades : bouton actif après un délai et seulement cadre visible ; ligne sans `\r`, donc la frappe Entrée reste requise ; IntersectionObserver v2 (`trackVisibility`), Chromium seulement [ASSUMED] |
| Ctrl-C qui tue un programme en cours | Déni de service | `\x03` seulement si `tcgetpgrp == pid du shell`, test et écriture dans la même boucle de l'assistant |
| Mode de permission hérité `bypassPermissions` | Élévation | Zone grise Z4 |
| Fuite : la ligne ou le contexte dans le journal, le SSE ou l'export | Divulgation | La proposition ne passe jamais par `diffuser` ni `serveur.log` ; le fichier de contexte est en 0600 dans `.cache`, effacé à la consommation ; le contrat `interdits` étendu (vf-cockpit-server.mjs:28-30) |
| Double lancement ou lancement concurrent | Altération | Une proposition à la fois ; pré-vol « mission vivante » (`vieDe`) ; lier par `--session-id` |

## Environnement

| Dépendance | Disponible | Version | Repli |
|---|---|---|---|
| `claude` | ✓ `/Users/samuel/.local/bin/claude` | 2.1.318 | Copier la commande |
| `python3` | ✓ | 3.14.6 | terminal indisponible (déjà géré) |
| `node` | ✓ | v26.5.0 | — |
| Chrome (suites navigateur) | ✓ | — | mode simulé des suites |

Aucun paquet externe à installer : pas d'audit de légitimité.

---

## Zones grises pour le cadrage

**Z1. Qui confirme, et où.**
- (a) Bouton dans P, proposition par IPC, confirmation dans Q, ligne sans `\r`. Recommandé.
- (b) Bouton dans P qui exécute directement.
- (c) Lanceur seulement dans Q : Q liste lui-même les phases, P ne fait qu'ouvrir le tiroir.
- (d) « Copier la commande » seulement.
- *Preuve :* toute route de P est appelable par une charge dans P (serve.mjs:508-514) ; la chaîne TERM-12 existe (test-cockpit-terminal-xss.sh:1-14) ; le bandeau de collage est réutilisable (vue.mjs:78-114).
- *Recommandation :* (a), avec (d) en repli sans `--terminal`. (b) casse TERM-12. (c) ne satisfait pas « depuis les cartes ». (a) garde le sens P → Q du navigateur fermé et met la décision dans l'origine que P ne pilote pas.

**Z2. Le canal P → Q côté serveur.**
- (a) Nouveau message IPC `proposition` et route Q `GET /proposition` ou un champ dans `/etat`. Recommandé.
- (b) Paramètre d'URL du cadre.
- *Preuve :* l'IPC existe (processus.mjs:4-5) ; Q ne lit que `theme` (processus.mjs:82 ; page.mjs:7) ; le rejeu au rechargement a déjà causé R1 (P71-D-36).
- *Recommandation :* (a). (b) viole P71-D-15 à la lettre et recharge le cadre. Il faut faire **amender P71-D-15 ou le confirmer** explicitement : « P peut proposer, jamais exécuter ».

**Z3. Où tourne `claude`.**
- (a) Une ligne écrite au shell existant, au repos. Recommandé.
- (b) Programme direct (`execvp('claude', …)`) quand aucune session n'existe.
- (c) Un second PTY dédié.
- (d) `claude -p` en arrière-plan côté serveur, avec des outils d'écriture.
- *Preuve :* une seule session (P71-D-05, session.mjs:118-123) ; premier plan mesurable (§3) ; le chat est délibérément en lecture seule (agent.mjs:14-20).
- *Recommandation :* (a), plus (b) en option. (c) rouvre P71-D-05 (« une seule session »). (d) donnerait à une route de P le pouvoir de lancer un agent qui écrit, sans terminal visible : contraire à la vision de Samuel (« une session de terminal dans l'idéal »).

**Z4. Mode de permission de la session lancée.**
- (a) Aucun drapeau : le `defaultMode` de l'utilisateur, qui peut valoir `bypassPermissions`.
- (b) Forcer `--permission-mode default`.
- (c) Choix dans le bandeau Q, par liste fermée.
- *Preuve :* le drapeau remplace `defaultMode` (cli-reference, ligne `--permission-mode`) ; ce poste tourne en `bypassPermissions`, observé dans la session de recherche.
- *Recommandation :* (b) par défaut, (c) en option, sans jamais `bypassPermissions` depuis un lancement. Un lancement né d'un clic sur une carte ne doit pas hériter d'une confiance plus large que la frappe manuelle.

**Z5. Pré-vols : bloquer ou avertir, et l'arbre sale.**
- (a) Bloquer seulement l'impossible (phase `fait`, terminal absent, premier plan occupé, compartiment hors motif) et avertir pour le reste (dépendances, mission vivante, phase plus avancée ailleurs). Recommandé.
- (b) Tout bloquer.
- Pour l'arbre sale : (i) ne pas le calculer (T-68-04) ; (ii) `git status --porcelain` avec `GIT_SUR` ; (iii) le confier à la 73 ou à la 78.
- *Preuve :* les dépendances sont une heuristique de prose (planning.mjs:49-54) ; arbres.mjs:6 exclut délibérément l'index et l'arbre de travail.
- *Recommandation :* (a) et (iii). Un faux positif bloquant sur une prose de ROADMAP serait pire qu'un avertissement, et le calcul de l'arbre sale doit vivre en un seul endroit, partagé avec la 73 et la 78.

**Z6. Quelles cartes portent « Lancer ».**
- (a) Phase, et mission prête ou en échec, dans l'onglet Projet. Recommandé.
- (b) Plus les cartes Équipe (« Reprendre la session » par `claude -r <id>`).
- (c) Plus une entrée globale « Lancer » dans l'en-tête.
- *Preuve :* les cartes Équipe sont des sessions en cours ou finies (equipe-carte.mjs:21-35) ; le tiroir est absent de `equipe.html` (tiroir.mjs:30) ; `addPanelSection` sert pour les cartes (viewer.html:2371).
- *Recommandation :* (a) d'abord. (b) seulement pour une session `terminé`, car reprendre une session vivante ailleurs ferait écrire deux clients dans le même transcript [ASSUMED]. (c) recoupe l'en-tête que possède la 78.

**Z7. Forme du prompt et entrée dans VibeFlow.**
- (a) Intention en clair avec `--append-system-prompt-file` pour le contexte.
- (b) `'/vf-dev <intention>'`.
- (c) `--agent vibeflow-head`.
- *Preuve :* vf-dev SKILL.md:9-14 ; head-governance.md:9-19 ; skill en prompt initial non vérifié ; nom d'agent exposé non vérifié.
- *Recommandation :* sonde de vague 0 sur (b) et (c) avec un skill et un agent témoins, puis retenir la forme qui incarne le head dans la session principale. Ne jamais citer de `gsd-*` dans le prompt.

**Z8. Le contexte du chat.**
- (a) Ignoré : la carte suffit.
- (b) Option « continuer cette conversation » par `claude -r <uuid> --fork-session`.
- (c) Résumé du chat écrit dans le fichier de contexte.
- *Preuve :* la session du chat est persistée et validée (serve.mjs:280 ; viewer.html:1908, 2119). Le chat se replie quand le tiroir est ouvert (tiroir-style.mjs:46).
- *Recommandation :* (a) en premier lot, (b) en option, après une sonde qui prouve que la session reprise retrouve ses outils et réglages complets. (c) ferait passer des réponses de modèle (dérivées du lab) dans la session sans relecture.

**Z9. Arrimage du lancement.**
- (a) `--session-id` généré, et la carte montre « lancée, session X » par l'onglet Équipe. Recommandé.
- (b) Aucun suivi.
- *Preuve :* `--session-id` existe (`claude --help`) ; who.mjs lit les transcripts par session (P69-D-22).
- *Recommandation :* (a). C'est ce qui permet d'anticiper un double lancement de la même phase.

**Z10. Séquencement avec les phases parallèles.**
- (a) Partir de `main` après le merge de `chore/cloture-71-inversion-terminal`. Recommandé.
- (b) Partir maintenant et rebaser.
- *Preuve :* §6, recouvrement 1.
- *Recommandation :* (a), et un recensement des branchements comme `71-BRANCHEMENTS-MERGE.md`, partagé avec la 78 (`vf-cockpit-server.mjs`, `VERSION`) et la 71.5 (styles du tiroir et de Q).

## Journal des hypothèses

| # | Hypothèse | Section | Risque si fausse |
|---|---|---|---|
| A1 | Un skill en prompt initial (`claude '/vf-dev …'`) se déclenche | §5, Z7 | Le prompt ne lance pas le head ; il faudra (a) ou (c) |
| A2 | `--agent vibeflow-head` incarne le head, et le nom exposé de l'agent | §5, Z7 | Mauvais point d'entrée |
| A3 | `tcgetpgrp` se comporte pareil sous Linux et fish | §3 | Test du premier plan faux sous Linux : sonde en CI |
| A4 | Les guillemets simples sont littéraux pour sh, bash, zsh et fish | §5 | Injection : couverte aussi par l'alphabet fermé et le mutant |
| A5 | Une session reprise par `--fork-session` récupère tous ses outils | §2, Z8 | La continuation du chat reste confinée |
| A6 | `git status` peut exécuter des filtres configurés par le lab | §4, Z5 | Seule la décision Z5 est en jeu |
| A7 | IntersectionObserver v2 détecte un cadre masqué (Chromium seulement) | Sécurité | Parade anti-détournement partielle ; le délai et la frappe Entrée restent |
| A8 | Reprendre une session vivante ailleurs corrompt son transcript | Z6 | Option (b) de Z6 à revoir |
| A9 | Le `cwd` du shell se lit par `/proc` (Linux) et `lsof` (macOS) | §5 | Utiliser un chemin absolu validé à la place |

## Sources

- Code lu cette session dans ce worktree (chemins et lignes ci-dessus) ; sonde `tcgetpgrp` dans le scratchpad de la session (`research72/pgrp.py`).
- `claude --help`, Claude Code 2.1.318 (poste de Samuel).
- [CLI reference — Claude Code](https://code.claude.com/docs/en/cli-reference) : `claude "query"`, `--name`, `--permission-mode`, `--append-system-prompt[-file]`, `--session-id`, `--worktree`, `--resume`, `--fork-session`.
- Sources tierces, non retenues comme preuve (skill en prompt initial) : [lowcode.agency](https://www.lowcode.agency/blog/claude-code-cli-commands-guide), [claudelog.com](https://www.claudelog.com/faqs/what-is-slash-commands-in-claude-code/).

**Valide jusqu'au :** 2026-11-19. La CLI évolue vite, et les branches 71-clôture et 78 vont bouger.
