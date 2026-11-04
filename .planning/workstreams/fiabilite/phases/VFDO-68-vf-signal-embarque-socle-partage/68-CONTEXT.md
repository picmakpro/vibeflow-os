# Phase 68: Embarquer vf-signal sur le socle partagé - Context

**Gathered:** 2026-11-03
**Status:** Cadrée (2026-11-03) — exécution conditionnée au merge de la Phase 69 et de la PR #196 (P68-D-09, P68-D-10)

Cadrage documentaire (aucun code). Mené par `vf-dev-manager` (mission `MISSION-68`, worktree
`.claude/worktrees/phase-68`, branche `feat/phase-68-vf-signal`, base `7370d604` = planification de la 69
sans code). Jalon `vibeflow-v2.0`, compartiment `fiabilite`. Ordre du jalon 69 → 68 → 70 → 71 → 72 (P69-D-13).

**Exigences :** VFSG-01 à VFSG-13. Famille `VFSG` proposée par `.planning/notes/2026-10-29-HANDOFF-jalon-v2.md`
§ 3, vérifiée libre le 2026-11-03 (0 occurrence dans `REQUIREMENTS.md` du compartiment), inscrite dans
`REQUIREMENTS.md` et dans la ligne `Requirements` de la Phase 68 du ROADMAP.

<domain>
## Phase Boundary

Le mod `vf-signal` (pane terminal : en-tête, fil de la boucle, vues mission / équipe / macro, bloc « toi »,
bandeau, commande `/vf-signal`) vit aujourd'hui hors dépôt, dans `~/.claude/mods/vf-signal` (marketplace
local `vf-mods`, scope user). La phase l'embarque dans le plugin `vibeflow`, **dans le module `cockpit`**,
branché sur le socle de lecture du cockpit (Phases 67 et 69) au lieu de sa propre lecture du disque, avec un
bouton « Ouvrir le cockpit », aligné sur la direction « Graphite » de `DESIGN.md`, validé en CI et livré dans
une release minor.

Elle corrige aussi le **point à cadrer du 2026-11-03** (ROADMAP, bloc de la Phase 68) : l'en-tête lit l'arbre
de la session seulement ; il doit signaler un arbre en retard sur `main`, voir la phase active d'un worktree
et ne plus prendre pour mission en cours une mission dont les nœuds n'ont jamais été refermés.

**Dans le périmètre :** le code du mod dans `plugin/cockpit/` ; un émetteur JSON versionné dans le socle
(`plugin/cockpit/scripts/`) ; la règle de mission vivante dans le socle (`avancement`) ; la déclaration du mod
dans `plugin/.claude-plugin/plugin.json` ; une étape CI de validation du mod ; la doc (README du module et
README racine FR/EN) ; la recette humaine ; la préparation de la release.

**Hors périmètre :** affichage du retard sur `main` et des worktrees dans le cockpit web (calculé dans le socle,
affiché par la pane seulement ; l'interface web relève des Phases 70 et suivantes) ; toute lecture réseau
(`git fetch` compris) ; terminal intégré (Phase 71) ; lancer du travail depuis le cockpit (Phase 72) ; le
retrait de l'ancien mod `~/.claude/mods/vf-signal` (geste de Samuel, documenté, P68-D-08) ; le tag et la
release GitHub (geste humain après merge).
</domain>

<decisions>
## Implementation Decisions

### Arbitrages de Samuel (AskUserQuestion, session principale Claude Code, 2026-11-03)

Huit questions posées en un seul envoi, chacune avec options et recommandation du manager ; relayées par la
session principale (SendMessage). Réponse de Samuel, mot pour mot : « Tout accepter (Recommandé) ». Les huit
recommandations sont donc retenues :

- **P68-D-01 (emplacement, chargement).** Le mod vit dans le module `cockpit` existant : une capacité, deux
  surfaces (web et pane terminal). Il ne s'affiche que si `cockpit=` figure dans le registre des modules
  installés (`scripts/.vibeflow-installed`). Aucun nouveau module.
- **P68-D-02 (source des données).** Le mod tire phase, jalon, missions et avancement du socle du cockpit, par
  un émetteur JSON en ligne de commande ajouté à `plugin/cockpit` (publie `avancement@1` par phase). Sa
  lecture maison du planning (`disk.ts`) est retirée.
- **P68-D-03 (arbre des agents).** La pane lit `who@2` du socle (toutes sessions, tous worktrees, 24 h,
  cohérent avec l'onglet Équipe de la 69). Les gestes « voir » et « demander l'arrêt » restent limités aux
  agents de la session courante.
- **P68-D-04 (arbre en retard, worktrees).** Sans réseau : l'en-tête compare HEAD à `main` local et à
  `origin/main` local, avec un badge « en retard de N commits sur main, dernier fetch il y a X » ; il liste
  chaque worktree (`git worktree list`) avec sa phase active et sa branche.
- **P68-D-05 (mission vivante).** Une mission n'est « en cours » que si son verrou de driver est tenu et non
  périmé, ou si son `progress_epoch` date de moins que le TTL (1 800 s). Sinon : « abandonnée, nœuds non
  refermés », grisée, avec le bouton humain d'élagage existant. La règle vit dans le socle (`avancement`),
  donc la carte Projet de la 69 en bénéficie aussi.
- **P68-D-06 (design).** La pane s'aligne sur « Graphite » (`DESIGN.md`) : couleurs de statut seulement,
  tokens nommés, plus de cyan ni d'orange de marque.
- **P68-D-07 (CI).** `claude plugin validate` et `claude plugin test` du mod entrent en CI. Touche
  `.github/workflows/ci.yml` : trailer `Gate-Touche` et revue `@picmakpro` (Willy) obligatoires (ruleset posé
  le 2026-09-23).
- **P68-D-08 (ancien mod, release, recette).** Le mod embarqué détecte l'ancien `~/.claude/mods/vf-signal`
  (sinon deux panes) et le signale ; le retrait reste un geste de Samuel, documenté. Release minor préparée
  (prochaine minor après la 69), tag et release GitHub après merge, par Samuel. Recette humaine pas à pas sur
  terminal plein écran, inline, VS Code et mobile.

### Conditions d'exécution (découlent des recommandations retenues, rappelées par la session principale, 2026-11-03)

- **P68-D-09.** P68-D-06 suppose `DESIGN.md` sur `main` : la PR #196 (`docs/design-md`) doit être mergée avant
  l'exécution de la 68. Sinon, le plan qui touche au rendu est gelé (pas de DA inventée en mission).
- **P68-D-10.** P68-D-02, D-03 et D-05 touchent le socle de la 69 (`vf-cockpit-avancement.mjs`,
  `vf-cockpit-interface.json`, `who@2`) : l'exécution de la 68 ne part qu'après le merge de la 69 sur `main`.
  Les plans sont écrits contre les plans de la 69 et son code lu à `34f74373` (`.claude/worktrees/phase-69b`) :
  ils sont **provisoires** ; avant l'exécution, rebase de `feat/phase-68-vf-signal` sur `main` puis
  re-validation par un plan-checker frais (doctrine pipelining N/N+1).

### Décisions techniques du manager (sur mesure, aucune n'élargit le périmètre)

- **P68-D-11 (déclaration du mod).** Le mod est déclaré au niveau du plugin (`plugin/.claude-plugin/plugin.json`,
  clé `hooks` vers un `hooks.json` qui ne porte que `modules`). Ce fichier ne s'appelle **pas**
  `plugin/cockpit/hooks/hooks.json` : l'engine fusionne tout `plugin/<module>/hooks/hooks.json` dans les settings
  et `merge-hooks.sh:302-304` meurt sur un fichier sans clé `hooks` (l'install du module échouerait). Source
  du mod sous `plugin/cockpit/signal/` (nom exact au plan). Chemin prouvé par `claude plugin validate plugin`
  (mesuré sur copie : un `../` interne est admis, une sortie du dossier du plugin est refusée).
- **P68-D-12 (état).** Les clés `$.state` sont rattachées au nom du plugin : `vf-signal.*` devient `vibeflow.*`
  (`interface PluginState`), sinon 10 erreurs de validation (mesuré).
- **P68-D-13 (le mod n'est pas posé par l'engine).** Le mod est lu depuis le cache du plugin (`$.plugin.root`),
  jamais copié chez l'utilisateur ; aucun type de pose de l'engine ne doit prendre les `.tsx`. `driver-lock.sh`
  se résout d'abord par `${$.plugin.root}/conductor/scripts/driver-lock.sh`, puis par les scripts posés
  (`<root>/.claude/scripts/`, `~/.claude/scripts/`). Amendée pour le socle par P68-D-28 (plus bas).
- **P68-D-14 (node).** Le mod appelle le socle par `$.process.run(['node', <script du plugin>, ...])`. Mesuré
  (sonde 2026-11-03) : `node` est trouvé via le PATH hérité ; sans `node`, l'appel est **rejeté** (ENOENT, pas de
  code de sortie) — le mod attrape ce rejet et affiche « node introuvable dans le PATH » au lieu de planter ;
  pas de chemin de node configurable. Sous `claude plugin test`, `process.run` n'atteint jamais la machine :
  le test du mod prouve l'argv construit et l'analyse du stdout (avec témoin rouge sur JSON invalide) ; la
  chaîne réelle node + `.mjs` se prouve par un test de l'émetteur dans les suites du cockpit et par un passage
  `claude -p --plugin-dir` consigné à la recette.
- **P68-D-15 (émetteur du socle).** Un seul émetteur JSON, schéma versionné déclaré dans
  `vf-cockpit-interface.json` (nom au plan, par exemple `signal@1`), qui agrège ce que la pane affiche :
  phases avec `avancement`, jalon, missions avec leur état de vie, worktrees, retard sur `main`, et l'équipe
  `who@2`. `readPlanning` rend des `Map` : l'émetteur sérialise, il ne recalcule rien. Aucune lecture réseau.
- **P68-D-16 (règle de vie, forme).** La mission vivante (P68-D-05) ajoute un état de mission (`abandonnee`)
  ou un champ de vie : la version du schéma `avancement` monte (même discipline que CKPT-28). Le critère lit
  l'état du verrou (`driver-lock.sh status`, tenu / `stale`, `progress_age_seconds`) ; il ne regarde jamais la
  date de modification d'un DAG (égale pour tous après un checkout, mesuré).
- **P68-D-17 (un ajout = un retrait, SOBR-01..08).** Retirés avec l'embarquement : la lecture maison du
  planning (`disk.ts` : STATE, ROADMAP, MILESTONES, BACKLOG, scan des DAG par date) ; le choix de la phase par
  `current_phase` du STATE (règle retirée par la 69, P69-D-08) ; les couleurs « Signal » en dur (`ds.ts`) ;
  `$.agent.list` comme source de l'arbre (gardé pour les gestes seulement).
- **P68-D-18 (gating).** Le mod lit le registre `scripts/.vibeflow-installed` du scope projet
  (`<root>/.claude/scripts/`) puis du scope user (`~/.claude/scripts/`) ; sans ligne `cockpit=`, il n'enregistre
  ni pane, ni bandeau, ni commande.
- **P68-D-19 (bouton « Ouvrir le cockpit »).** Lance le lanceur du cockpit (`vf-cockpit.mjs open`, posé ou
  depuis `$.plugin.root`) et affiche l'URL rendue (port stable par lab) ; geste humain, aucun agent.
- **P68-D-20 (chemins de machine).** Le test du mod contient `HOME: '/home/<user>'`
  (`vf-signal.test.tsx:58`) : `check-machine-paths.sh` rougirait ; le chemin est neutralisé à l'import.
- **P68-D-21 (version du module).** Pas de nouveau `module.json` : les compteurs de modules des README ne bougent
  pas (`check-version-sync.sh`). Le module `cockpit` monte d'une minor après la version posée par la 69.

### Arbitrages de Samuel sur les points à décider de 68-01 (AskUserQuestion, session principale Claude Code, 2026-11-03)

Relayés par la session principale (SendMessage) ; réponses mot pour mot entre guillemets.

- **P68-D-22 (deux DAG d'un même compartiment).** « Oui, par le verrou de phase (Recommandé) ». Une mission est
  vivante si le verrou de **sa phase** (`driver-lock.sh --ws --phase`, mergé sur main par la PR #197) est tenu ou
  récent ; le DAG porte sa phase ; `driver-lock.sh` n'est pas modifié. Précise P68-D-05 et P68-D-16 ; remplace
  l'hypothèse P68-PL-02 (verrou du compartiment).
- **P68-D-23 (source des verrous illisible).** « « État inconnu » ». Troisième état explicite, ni `running` ni
  `abandonnee`, porté par le contrat `avancement`, affiché et testé. Remplace l'hypothèse P68-PL-03.
- **P68-D-24 (bloc backlog de la vue macro).** « Le retirer (Recommandé) ». Confirme P68-PL-11.
- **P68-D-25 (ordre du lanceur du cockpit).** « Le module posé dans le projet (Recommandé) ». Confirme P68-PL-12
  (posé projet, posé user, puis `$.plugin.root`).
- **P68-D-26 (mission sous verrou de compartiment seul).** Question posée : une mission menée sous le seul verrou
  du compartiment (forme d'avant la PR #197) s'afficherait-elle « abandonnée » ? Réponse de Samuel, mot pour mot :
  « Repli sur le verrou du compartiment (Recommandé) » (AskUserQuestion, session principale Claude Code, 2026-11-03,
  relayé par la session principale). Règle : le verrou de la phase passe d'abord ; sans verrou de phase, si le
  verrou du compartiment est tenu ou récent, la mission est vivante ; sinon `abandonnee` ; une source illisible donne
  `inconnu` (P68-D-23). Précise P68-D-22.
- **P68-D-27 (verrou de phase périmé, compartiment tenu) — décision du manager, pas un arbitrage de Samuel.**
  Cas laissé ouvert par P68-D-26 : le plan garde « la phase d'abord », même périmée, donc la mission sort
  `abandonnee`. Motif : le script empêche presque toujours ce cas, car le compartiment refuse l'acquire tant qu'un
  verrou de phase, même périmé, n'a pas été repris. La session principale a choisi de ne pas poser la question à
  Samuel (consigne du 2026-11-03). Un témoin figera ce comportement ; il sera ajouté à 68-01 au nœud `revalid-68`. Fait : témoin V9.8 de 68-01 (2026-11-04).

- **P68-D-28 (option `pluginRoot` retirée) — décision du manager, pas un arbitrage de Samuel (2026-11-04).**
  Retirés : l'option `pluginRoot` de `driverLockScript` et la CLI `--plugin-root` de l'émetteur. Motif : la règle
  « conductor voisin » de la 69 (`vf-cockpit-paths.mjs`, fonction `driverLockScript`, l. 72-74 sur `main` à 794c6dba)
  résout déjà `<plugin>/conductor/scripts/driver-lock.sh` quand le socle tourne depuis `<plugin>/cockpit/scripts`, ce qui
  tient l'intention de P68-D-13 sans code neuf ; `driverLockScript` n'est plus modifié par la 68. Témoin positif :
  W18.1 de `test-cockpit-who.sh` ; un script planté dans le lab n'est jamais exécuté (V7.1 de 68-01, S6.3 de 68-03).
  Amende P68-D-13 (renvoi, texte inchangé). Ne change pas la résolution côté mod : les paramètres `pluginRoot` des
  fonctions du mod (68-05 à 68-07 : racine du plugin, `$.plugin.root`, pour situer l'émetteur, le lanceur du cockpit et
  `driver-lock.sh` du geste d'élagage) ne sont pas l'option retirée.
- **P68-D-29 (isolation des suites face au conductor voisin) — décision du manager, pas un arbitrage de Samuel
  (2026-11-04).** Constat du correcteur des plans : sur `main`, un outil de test qui calcule le planning sans dossier de
  scripts explicite tombe sur le vrai `plugin/conductor/scripts/driver-lock.sh` du dépôt par la règle « conductor
  voisin » ; épingler `HOME` ne suffit donc plus. Règle : toute suite de la 68 qui veut un résultat indépendant du
  poste passe au processus qui calcule un dossier de scripts explicite hors de toute disposition `…/cockpit/scripts`
  (`VF_COCKPIT_SCRIPTS_DIR` ou option `scriptsDir`), vide ou portant son faux `driver-lock.sh` ; c'est la forme
  déjà retenue par la 69 (`cb5525dc`). S'applique à V5.1 de 68-01 (« aucun script trouvable » : dossier de scripts
  vide en plus du `HOME` vide) et à l'épinglage de la tâche 3 de 68-01 (suites `direct`, `equipe`, `responsive`,
  `who`, `projet`, `avancement`). Code de `driverLockScript` inchangé.
- **P68-D-30 (jalon de l'en-tête) — décision du manager, pas un arbitrage de Samuel (2026-11-04).** Constat de
  l'exécuteur de 68-05 : l'en-tête du mod n'affiche plus le jalon, qu'il lisait dans le STATE (lecture retirée,
  P68-D-17). Règle : l'en-tête affiche le jalon de la phase active de l'arbre courant, lu dans `signal@1` (le jalon de
  `jalons[]` dont `phases` contient cette phase) ; sans phase active ou sans jalon qui la contienne, aucun jalon n'est
  affiché, jamais un repli sur le STATE. Appliqué en 68-06 (`en-tete.tsx` ajouté à son périmètre), avec témoin rouge.

### Arbitrages de Samuel pendant l'exécution (AskUserQuestion, session principale Claude Code, 2026-11-04)

Relayés par la session principale (SendMessage) ; réponses mot pour mot entre guillemets.

- **P68-D-31 (périmètre de 68-11, Q1).** « Module seul, racine groupée (Recommandé) ». 68-11 monte le module `cockpit`
  de v1.1.1 à v1.2.0 avec son CHANGELOG et porte la relecture adverse SOBR-04 du diff de la phase ; aucun bump racine
  (`VERSION`, `plugin.json`, `marketplace.json`, historique des README, CHANGELOG racine) : il part avec la release
  groupée. VFSG-13 est reformulée en ce sens. Amende P68-D-08 sur ce seul point.
- **P68-D-32 (porte de légitimité du paquet, Q2, 68-09 tâche 1, T-68-SC).** « Légitime, 2.1.318 (Recommandé) ».
  `@anthropic-ai/claude-code` épinglé en `2.1.318` dans l'étape CI.

### Points de procédure (documentés, sans arbitrage — consigne de la session principale, 2026-11-03)

- Version minimale de Claude Code : aucun champ de version minimale n'est documenté pour les mods ; la version
  de `claude` utilisée en CI et à la recette est consignée (68-09, 68-10).
- Délai de revue de Willy : la PR qui touche `.github/` attend la revue `@picmakpro` ; délai hors de la main de
  la mission, constaté à 68-09.
- Croisement des identifiants `who@2` et `$.agent.list()` : constaté à la recette (68-10), pas tranché d'avance.

### Attendu sur `reste` (point venu du manager de la 69, 2026-11-03)

Pour une phase `a-faire`, la 69 livre `reste = ["verification","cloture"]` (lecture littérale de P69-D-07). Vérifié
contre les plans de la 68 au tour de révision (voir 68-01).

### Constats mesurés (trois recherches et une sonde en lecture seule, 2026-11-03)

- Mod : 17 fichiers source (≤ 226 lignes chacun, ADR-035 tenu), `tsc` strict, `claude plugin validate --strict`
  et `claude plugin test` (3/3) verts sur copie. Le cache `vf-mods/vf-signal/0.1.0` diverge de la source sur
  6 fichiers : la **source** `~/.claude/mods/vf-signal` est la référence d'import.
- En-tête : `root = $.session.root()` (`disk.ts:130`), phase = `current_phase` du STATE de cet arbre
  (`disk.ts:138`), mission = DAG de date de modification maximale (`disk.ts:96`) puis premier nœud `running`
  (`derive.ts:61-63`). Les `dag-*.json` de `missions/` sont ignorés (`disk.ts:95`). `MISSION-59` garde un nœud
  `running` jamais refermé.
- Socle : aucune détection de retard sur `main` (aucun `rev-list`, `merge-base`, `origin/` dans
  `plugin/cockpit/scripts`) ; `readPlanning` ne lit que `<root>/.planning` ; `who` applique le TTL de 1 800 s
  aux nœuds `running`, `avancement` non (`avancement.mjs:57,91` à `34f74373`).
- `driver-lock.sh status` expose `stale`, `age_seconds`, `progress_age_seconds`, `step` ; le méta du verrou porte
  `branch=` et `worktree=` mais le JSON de `status` ne les expose pas. Le verrou par phase vit sur une branche
  non mergée (`feat/driver-lock-par-phase`) : le plan lit la version de `driver-lock.sh` présente sur `main` à
  l'exécution.
- `origin/main` local n'est frais qu'au dernier fetch ; son âge se lit sans réseau (date de `FETCH_HEAD`).
- Packaging : `plugin.json` ne déclare aujourd'hui que `"skills": "./installer"` ; `claude` n'est pas installé
  en CI (`ci.yml`) ; `validate` et `test` passent sous `HOME` vide sur macOS, non prouvé sous Linux. L'API des
  mods est « early access » (`reference.md:5`) : un module qui ne se charge pas ne laisse qu'une ligne au log
  de debug hors rechargement à chaud.
- Graphite (`origin/docs/design-md:DESIGN.md`) vise vf-signal nommément (l. 15) : sombre d'abord avec thème
  clair, monochrome, statuts fait `--recent`, en cours et à recetter `--sev-medium` (mot écrit en toutes
  lettres), à faire `--text-4`, bloqué `--sev-high` ; aucune couleur en dur.

### Points ouverts

- Le CI Linux de `claude plugin validate/test` sans session authentifiée n'est pas prouvé : premier geste du
  plan CI, témoin rouge compris ; s'il échoue sous Linux, remontée à Samuel (pas de contournement).
- La PR touchant `.github/` exige la revue de Willy : délai hors de la main de la mission.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/workstreams/fiabilite/ROADMAP.md` — bloc Phase 68 (Goal, point à cadrer du 2026-11-03)
- `.planning/notes/2026-10-29-HANDOFF-jalon-v2.md` § 3 — points à trancher, requirements candidats `VFSG`
- `~/.claude/mods/vf-signal/` — source du mod (lecture seule, hors dépôt)
- `.planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-01-PLAN.md`, `69-03-PLAN.md`,
  `69-CONTEXT.md` (P69-D-08, P69-D-10, P69-D-13) — contrats `avancement@1`, `who@2`
- `plugin/cockpit/scripts/vf-cockpit-interface.json`, `vf-cockpit-planning.mjs`, `vf-cockpit-avancement.mjs`
  (69), `vf-cockpit-who.mjs`, `vf-cockpit.mjs`, `vf-cockpit-port.mjs`
- `DESIGN.md` « Graphite » — `origin/docs/design-md` (PR #196)
- `plugin/_internal/vibeflow-update.sh` (registre `.vibeflow-installed`, `merge_module_hooks`),
  `plugin/conductor/scripts/merge-hooks.sh:302-304`
- `scripts/check-version-sync.sh`, `scripts/check-machine-paths.sh`, `.github/workflows/ci.yml`
- Skill `plugin-authoring` (référence de l'API des mods)
</canonical_refs>
