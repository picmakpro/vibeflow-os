# Backlog — idées différées (hors milestone courant)

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Template d'agent installable s'appuyant sur dev-orchestrator — CLOS (2026-10-16) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Ligne d'index absente pour ADR-071 dans `docs/ADR.md` — DIFFÉRÉ (2026-09-18) — CLOS (2026-10-16) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## `test-scaffold-docs.sh` cas 22 fige en dur le nombre de références d'un module — DIFFÉRÉ — CLOS (2026-10-16) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## Combler les gaps de couverture inspirés du catalogue `agency-agents` — CLOS (2026-10-12) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-08.md — ## Un gate câblé sur un seul compartiment de workstream laisse les autres sans garde — DIFFÉRÉ (2026-09-23) — CLOS (2026-10-08) -->

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Emprunts qualité de code à Ponytail, pstack et thermo-nuclear review — INVESTIGUÉ 2026-10-10 — CLOS (2026-11-05, recherche tierce renvoyée à l'index de recherche) -->
## Équivalent Codex des skills de modules Type 1 — consigné 2026-10-06

**Statut : dette consignée par la Phase 41.4 (P414-D-03), non traitée : exige une modification de l'installeur.**
**Constat.** Le Type 1 copie le SKILL.md seul : un `plugin/{mod}/agents/` serait installé et linté comme agent ; seuls les skills nichés Type 2 transportent `agents/openai.yaml`. Un skill Type 1 passé user n'aurait donc aucun équivalent Codex (`plugin/_internal/vibeflow-update.sh` l.2290-2322).
**Modules concernés.** installer, planning-core, consolidator, infrastructure-audit, audit-architecture, kpi-analyst, mobile-test, software-architecture.
**Issue de Q1 (plan 41.4-08).** Option (a), P414-D-17 : arbitrage Samuel, AskUserQuestion session principale, 2026-10-06 ; 0 skill user aujourd'hui (26 classés `vf-invocation: model`), donc aucune dette Codex active ; elle le devient au premier skill Type 1 passé user.

**Absorbé : A2 — collision de nom entre scripts de modules (consigné 2026-09-25, Phase 42).** `plugin/_internal/vibeflow-update.sh` pose les scripts
de TOUS les modules à plat dans un seul `.claude/scripts/` : un même nom de `.sh` porté par deux modules en écrase un silencieusement, sans diagnostic (dette antérieure
à la Phase 42, même famille que CR-01 côté agents). Piste : diagnostic avant écrasement, ou namespacing par module. Déclencheur : premier incident réel de collision, ou revue de fond de l'installeur.

## Routage « crée une PR / ship » vers gsd-ship contre « ouvrir une PR = geste VibeFlow » — consigné 2026-10-06

**Statut : consigné par la Phase 41.4 (P414-D-16, décision du manager), non cadré — changer une route est hors périmètre de la phase.**

**Constat.** `intent-routing.md:76` (ligne 77 depuis les ajouts de la Phase 41.4) route « crée une PR / ship » vers `gsd-ship` ; `GSD-PIPELINE.md:122` et `mission-contracts.md` §Isolation de branche font de l'ouverture de PR un geste de l'équipe, désormais contrôlé par E3 avec le merge-danger call (POCK-06). Aucune route n'a changé.

**À trancher au cadrage.** Une demande « crée une PR » en conversation doit-elle aller à `gsd-ship` (PR sans merge-danger call ni contrôle E3) ou au geste de l'équipe ?

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## Traçabilité des arbitrages humains dans les messages de commit — ADOPTÉE 2026-09-10 -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-08.md — ## Choisir la partition du planning AU DÉMARRAGE, pas après coup — demandé 2026-09-23 — CLOS (2026-10-08) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## Convergence de contenu à l'update de module (manifeste par module) — CLOS (2026-10-12) -->
## Classe « un gate conclut sans avoir jugé » (juges d'artefact de planning, nettoyage auto-déclaré, énumération de compartiments, `check-machine-paths.sh`) — DIFFÉRÉ (2026-11-05)

**Fusion du 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F4). Même famille (« une preuve incapable de rendre rouge ») ; le dernier cas est neuf et prouvé. Texte intégral des sujets absorbés : `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`, aux titres cités. Priorité P2 pour le cas de `check-machine-paths.sh`, P3 pour le reste.

- **`scripts/check-machine-paths.sh` : vert sous macOS, rouge sous Linux — en cours de correction, mandat séparé, 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Corriger maintenant (Recommandé) » ; il reste ouvert jusqu'au merge du correctif). Origine : Phase 70, deux fois, des chemins `/Users/<user>/…` dans les plans passaient en local et rougissaient en CI Linux (plans corrigés en `c7217940`). **Cause démontrée le 2026-11-05** sur un dépôt jetable : l'awk de macOS (20200816), en locale UTF-8, s'arrête au premier octet non UTF-8 (`towc: multibyte conversion failure`, rc 2) ; la ligne 125 lance `xargs -0 awk` sans `LC_ALL=C`, avec `2>/dev/null` et sans contrôle du rc, donc les fichiers suivants du lot passent non balayés (1 chemin sur 3 vu en `C.UTF-8`, 3 sur 3 en `LC_ALL=C`). L'hypothèse d'origine (lots d'arguments, octets non ASCII) est précisée, celle d'un « compte local invisible » n'est pas ce que montre la sonde. Correctif : `LC_ALL=C`, rc d'awk contrôlé, témoin rouge.
- **Juges d'un artefact de planning** (absorbé : « Les juges d'un artefact de planning ne gardent pas ce qu'on croit », mesuré 2026-09-23). Instance du point 1 FERMÉE (`7ba80d1f`, Phase 41.1 : `check-state-integrity.sh:118-121`, rc 64 sur chemin absolu), classe OUVERTE : balayer les autres gates qui sautent un invariant en silence. Points 2 à 5 non re-mesurés depuis le 2026-09-23 : `check-dev-bootstrap.sh` est un routeur (0 y est le MAUVAIS état) ; `status` exigé par aucun juge ; `REQUIREMENTS.md` d'un compartiment lu par aucun juge (dette à nommer, jamais un champ à supprimer, décision de la session principale du 2026-09-23) ; aucune commande unique du moteur ne produit un compartiment conforme. La matrice des cinq états est dans l'archive du 2026-10-12.
- **Gate de nettoyage auto-déclaré** (absorbé : « `check-agents.sh` ne couvre que les chemins auto-déclarés par un protocole de spike, pas l'état réel du disque », 2026-09-15). Le gate du spike SKIL-01 (`34-02-PLAN.md:237`, `34-VALIDATION.md:55`) est passé vert avec trois résidus sur disque. Forme attendue : recherche élargie de l'état réel (cache plugins, `~/.claude.json`, registres), jamais une liste auto-déclarée, avec mutation rouge prouvée. Absorbé là : un bloc `<verify><automated>` qui écrase un script réel sans `trap` (`25-02-PLAN.md:154`) se durcit par `trap ... EXIT INT TERM`. Déclencheur : le prochain plan qui pose un gate de nettoyage.
- **`vf_ws_enumerate`** (absorbé : « Pour Samuel : `vf_ws_enumerate` ne restitue pas fidèlement un compartiment à saut de ligne », 2026-09-28, propriétaire Samuel). `plugin/planning-core/scripts/workstream-policy.sh:305-306` : `printf '%s\n' "$(cd …)"` puis `found=1` sans condition ; un compartiment à saut de ligne, ou sans bit `x`, devient invisible sans diagnostic et `detect-gsd-engine.sh` (priorité 2bis) rend 3 « terrain libre ». Même trou dans `check-planning-state.sh` (~L136-141, compteur gonflé). Piste : délimiteur NUL des deux côtés, ou rc de `cd` testé avant d'émettre. Déclencheur : la prochaine évolution de ces deux fichiers.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Les juges d'un artefact de planning ne gardent pas ce qu'on croit — mesuré 2026-09-23 — CLOS (2026-11-05, fusionné dans Classe gate qui conclut sans juger) -->
## Formats de sortie hétérogènes entre les 12 suites de `dev-orchestrator` — DIFFÉRÉ

**Capturé :** 2026-08-18, hygiène documentaire de clôture de la Phase 18 (mandat vf-coder). Hors
périmètre de cette phase (aucun code de test n'est touché) — remonté sans corriger.

**Le défaut :** chaque suite de `plugin/dev-orchestrator/scripts/tests/` imprime son bilan dans un
format textuel différent. Mesuré en ré-exécutant les 12 suites (2026-08-18) :

Six formats distincts sur 12 suites : `== résultat : N ok, 0 ko ==` (7 suites), `== résultat : N OK / 0 KO ==` (1), le même suivi de `/ 0 SKIP` (1, sur-ensemble textuel du précédent),
`== Résultat : N OK, 0 KO, 0 SKIP ==` (1), `== bilan : N cas — N OK / 0 KO ==` (1), `  Bilan : N OK, 0 KO` (1, `test-inject-mcp-tools.sh`). Suites nommées : détail archivé.
Toutes vertes à l'exécution directe (2026-08-18). Un collecteur calé sur UN motif littéral classe à tort en échec, ou en faux vert par sous-chaîne partagée (`OK / 0 KO` dans `OK / 0 KO / 0 SKIP`).

**Piste de fix :** un unique contrat de sortie machine-lisible (ex. une dernière ligne
`RESULT: pass=N fail=N skip=N` commune aux 12 suites, imprimée en plus — jamais à la place — du
libellé humain existant, cf. `feedback_libelles-ok-geles.md` : les libellés `ok` gelés s'ajoutent,
ne se réécrivent jamais). Un collecteur se cale alors sur ce contrat unique, jamais sur la prose.

**Absorbé, LIVRÉ : `test-scaffold-docs.sh` cas 22** (consigné 2026-09-15, Phase 40). L'attendu est dérivé du dossier au lieu d'un littéral, `8f22fa61` (`plugin/conductor/scripts/tests/test-scaffold-docs.sh:275-277`). Texte d'origine : `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`, § « Détail historique des entrées réécrites ».

**Absorbé : faux rouge local de `plugin/_internal/tests/test-vibeflow-update.sh` (constaté 2026-09-28, Phase 44).** Le garde-fou « `~/.claude` intact » compte
`~/.claude/skills/synced/`, que le runtime réécrit pendant le test (`.last-complete-round`, `manifest.json`) : 1510/1509 puis 1509/1510 sur HEAD `72eb408`, vert sur un export figé à `424cb23`.
Même classe : un verdict de suite lu sur un signal instable. Propriétaire : Samuel. Déclencheur : prochaine évolution de ce test ou de son garde-fou, ou un faux rouge bloquant une CI/un push.

Texte intégral : `.planning/archives/backlog/racine-BACKLOG-2026-10-16.md` § Détail historique des entrées condensées.

## `save()` de `dag.sh` : lost update entre deux `mark` concurrents et trois findings voisins — DIFFÉRÉ

**Capturé :** 2026-08-17, demande explicite de Samuel après le rapport d'exécution de la Phase 33 (finding pré-existant de la revue de mission, hors périmètre 33). Réécrit le 2026-11-05 sur ce qui reste ; texte d'origine : `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`, § « Détail historique des entrées réécrites ».

**Livré :** l'écriture atomique de `save()` (fichier temporaire, fsync, `os.replace`) par `5d535143` (plan 67-01, PR #187, v2.75.0), et l'écriture de la cible d'un DAG lien symbolique par `0a2c8329` (`plugin/conductor/scripts/dag.sh:149-171`).

**Reste (a), le lost update :** `save()` réécrit le fichier de DAG sans verrou ; deux `mark` concurrents font une lecture-modification-écriture et le dernier écrase le premier, sans erreur ni trace. `dag.sh` sert le dispatch parallèle, et `mark` écrit aussi `progress_epoch` (D-33-A). La piste conditionnait le verrou (type mutex du driver-lock, `ln_atomic`, Phase 32) à une mesure de collisions réelles, jamais faite. La preuve devra être un cas de concurrence réel rouge sous mutation, pas un test d'API (même exigence que T46, Phase 32).

**Reste (b), les findings voisins de la revue de la Phase 33, non re-sondés :** `sanitize_field()` incomplet sur les caractères de contrôle ; `vf_guard_unavailable()` sans validation d'argument ; TOCTOU sur le `takeover` legacy (`.planning/missions/2026-08-17-phase-33-watchdog-notifications.md`, § findings pré-existants). Priorité P3.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Gate machine sur l'observance de `mission-flow.md` (Phase 33, S1 option (c)) — DIFFÉRÉ — CLOS (2026-11-05, abandonné) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Alignement « AI Agents in Depth » (Bojie Li) — milestone candidat — INVESTIGUÉ — CLOS (2026-11-05, recherche tierce renvoyée à l'index de recherche) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## Notifications de progression des agents managers — CLOS -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## check-agents : périmètre des agents tiers (gsd-*, autres chaînes) — CLOS -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## Skill-installer global (multi-agents) — CLOS -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Investiguer ICM (Interpretable Context Methodology) — « folder structure as agent architecture » — INVESTIGUÉ — CLOS (2026-11-05, recherche tierce renvoyée à l'index de recherche) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## AGTS-02 — sortie d'expérimental de `mobile-test`(-team) : REPORTÉE avec trace — CLOS (2026-11-05, tracé par le ledger seul) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## Budget des SKILL.md et du bootstrap — sans enforcement machine (différé de la Phase 25, 2026-09-15) — CLOS (2026-10-12) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## check-agents.sh ne couvre que les chemins auto-déclarés par un protocole de spike, pas l'état réel du disque — CLOS (2026-11-05, fusionné dans Classe gate qui conclut sans juger) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Blocs `<verify><automated>` de plan qui écrasent un script réel sans `trap` — DIFFÉRÉ (2026-09-15) — CLOS (2026-10-16) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Évasion de mesure du budget d'instructions par bloc de code fenced — DIFFÉRÉ (2026-09-15) — CLOS (2026-11-05, abandonné) -->
## Dérive documentaire et fragilité latente révélées par le gate de budget d'instructions — DIFFÉRÉ (2026-09-15)

**Capturé :** 2026-09-15, clôture documentaire de la Phase 25 (mandat vf-coder), quatre constats
remontés par les juges de cette mission, tous hors du périmètre déclaré de la phase. Texte intégral
d'origine, dont le détail des points 1 et 4 : `.planning/archives/backlog/racine-BACKLOG-2026-10-12.md` § « Détail historique des entrées condensées ».

**Fermés (Phase 40.1, 2026-09-17), re-mesurés le 2026-10-12 :**
- point 1 (`plugin/validator/README.md:10` affirmait « 249 lignes » pour 250), plan 40.1-11 (`ea7f29d6`) :
  le README dit « marge de 50 lignes » ; `plugin/validator/AGENT.md` = 250 lignes ;
- point 4 (étape CI `check-instruction-budget`, affectation à `rc=2` fatale sous `pipefail`), plan
  40.1-03 (`52256c0d`) : mesure de la fixture à code capturé, sans `|| true`.

**Toujours ouverts (re-mesurés le 2026-10-12) :**
2. **`.planning/codebase/CONVENTIONS.md:56`** décrit des codes de sortie « normalisés » (`2` = erreur
   d'usage, `3` = INDÉTERMINÉ) que `check-instruction-budget.sh` inverse délibérément (`64` usage, `2`
   indéterminé, `3` = ratchet non armé). C'est le troisième gate à dévier de cette ligne : « normalisés »
   ne décrit plus le parc réel.
3. **`.planning/codebase/TESTING.md`** : l.98, « les gates suivent tous le contrat F13 » est faux (trois
   gates dévient, cf. point 2) ; l.30-32, la liste du job `gates` compte 3 puces pour bien plus d'étapes
   réelles.

**Pourquoi non corrigé ici :** `CONVENTIONS.md` relève de la doctrine transverse du repo, hors du
périmètre de la Phase 25 (budget d'instructions).

**Déclencheur de reprise :** le point 1 avant l'armement du ratchet en Phase 40 (dur) ; les points
2-3 à la prochaine révision de `CONVENTIONS.md`/`TESTING.md` ou dès qu'un quatrième gate dévie du
patron F13/codes normalisés ; le point 4 à la prochaine édition de l'étape CI concernée, ou plus
tôt si quelqu'un ajoute `shell: bash` à une étape du job `gates`.

**Absorbé : lignes d'index absentes dans `docs/ADR.md` (mesuré 2026-09-17, re-mesuré 2026-10-16).** La table d'index saute ADR-071 (`## ADR-071` : l.2487) ET ADR-075
(`## ADR-075` : l.3028) : après la ligne ADR-070 (l.41) vient ADR-072 (l.42), et après ADR-074 (l.44) vient ADR-076 (l.45). Hors périmètre des phases qui les ont posées.
Déclencheur : prochain passage sur `docs/ADR.md`.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## Posture de protection de `main` — TRANCHÉ : phase dédiée à inscrire (2026-09-15) — CLOS (2026-10-12) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## T-25-SC — journal de sécurité de la Phase 25 : TRANCHÉ, geste de clôture (2026-09-15) — CLOS (2026-10-12) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-12.md — ## `check-overlaps.sh` : `present()` aveugle à un agent local installé sous son nom de fichier canonique — DIFFÉRÉ — CLOS (2026-10-12) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Protection de `main` côté GitHub — DIFFÉRÉ, en attente d'un accès admin (2026-09-17) — CLOS (2026-11-05, écart accepté) -->
## Mise en conformité du corpus de skills en dérive procédurale non déclarée (différé de la Phase 43, 2026-09-24)

**Capturé :** 2026-09-24, cadrage de la Phase 43 (compartiment `gouvernance`, `43-CONTEXT.md` D-Q5).

**Le défaut :** le futur `check-skills.sh` signalera les skills dont la forme est procédurale (gate
bloquant, livrable remis à un tiers, couche de qualité) sans que leur nature le déclare. Dans cette
phase, il ne fait qu'**avertir** : réponse de Willy (AskUserQuestion, session principale, 2026-09-24).
C'est un écart assumé par rapport à la doctrine D-11 de la Phase 42 (invariants armés en erreur,
corpus corrigé dans la même phase).

**Déclencheur de reprise :** le gate existe et a mesuré le corpus réel (25 `SKILL.md` sous `plugin/`
au 2026-09-24). Reprendre avec la liste des skills signalés, puis décider de l'armement en erreur.

## Pour Samuel — le mode large `vf-mcp-consumer` injecte les serveurs du scope global, dont context7 chez `vf-app-fixer` (constaté 2026-09-24)

**Capturé :** 2026-09-24, panel de décision sur la question MCP du cadrage de la Phase 43 (compartiment
`gouvernance`). Hors périmètre de la Phase 43 : sur décision de Willy (AskUserQuestion, session
principale, 2026-09-24), il est inscrit comme finding pour Samuel, **sans correctif dans cette mission**
(ADR-031). Polarité : `dev-orchestrator` et `mobile-test-team` (Samuel).

**Le défaut :** `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` réunit les serveurs du scope
projet (`.mcp.json`) et ceux du scope global (`~/.claude.json`, clé `mcpServers`) pour tout agent qui
porte `vf-mcp-consumer: true` (l.26-31, l.222). Il en résulte un écart de doctrine :
- ADR-051 (« Cloisonnement », `docs/ADR.md:469`) garde à `vf-app-fixer` son interdiction ADR-045
  (pas de context7, pas de web) ;
- les conséquences négatives d'ADR-051 disent qu'un serveur déclaré au seul niveau utilisateur n'est
  pas injecté « par conception » ;
- le script justifie l'union par « ADR-051-B », un addendum **absent** de `docs/ADR.md`.

**Preuve rejouée** (2026-09-24, copie jetable de `vf-app-fixer.md` dans le scratchpad de session, sans
`.mcp.json` de projet) :
`inject-mcp-tools.sh --target <copie>/agents --mcp-json <absent> --dry-run` →
`vf-app-fixer.md : (dry-run) ajouterait mcp__context7__*, mcp__xpoz-mcp__*`. Ce sont exactement les
deux serveurs de `~/.claude.json` de ce poste.

**À trancher par Samuel :** filtrer le scope global pour les agents cloisonnés, ou revenir au seul
scope projet pour le mode large, ou écrire l'addendum ADR-051-B qui assume l'union et amende ADR-045.
Tant que rien n'est tranché, tout lab dont `~/.claude.json` déclare context7 donne context7 à
`vf-app-fixer` à l'installation.

**Absorbé : faux vert de `inject-mcp-tools.sh --verify` sur un dossier mixte (consigné 2026-09-26, Phase 43).** `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh:505` :
la branche d'une valeur `vf-mcp-tools` malformée fait `continue` sans `indeterminate.append(base)` (l.509-513 le fait pour « serveur absent ») : `--verify` rend `rc=0` sur un dossier mixte.
Impact actuel nul (`ensure-deps.sh` l'appelle fichier par fichier) ; la règle 4 de `check-capability-activation.sh` lit ce mode. Revue « majeur », audit sécurité « mineur », non tranché.
Déclencheur : prochaine évolution de `inject-mcp-tools.sh` ou de `check-capability-activation.sh`.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## ADPT-06 — canal `hooks`/`plugins` du dépôt jugé jamais répété — RÉSORBÉ (2026-09-24) -->
## Juges et digests D-08 : interdits du lab absents du digest, critère RGPD absent des grilles — DIFFÉRÉ (2026-11-05)

**Fusion du 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F6). Même origine (Phase 42, condition de Samuel sur D-08, 2026-09-25). Texte intégral des deux sujets absorbés : `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`, aux titres cités. Priorité P3. Rien n'est tranché pour `gouvernance` (« Non pour l'instant (Recommandé) », même date).

- **Écart D-08(b)** (absorbé : « Écart D-08(b) : digest du manager sans interdits du lab sur le chemin vf-dev-manager → vf-design-judge », 2026-09-25). La condition (b) est remplie côté `vf-design-manager` → `vf-design-judge`. En étage implémentation croisée (`livrable: specs+implementation`), c'est `plugin/dev-orchestrator/agents/vf-dev-manager.md` qui compose le digest : 0 occurrence de « interdits » dans ce fichier (constat du 2026-11-05). Module de la polarité de Samuel (D-12). Pistes : `vf-dev-manager` porte la même consigne (commit dev-orchestrator, mandat séparé) ; ou digest composé par délégation à `vf-design-manager` ; ou écart jugé sans conséquence par Samuel. Détail : `42-05-SUMMARY.md` § Écart non résolu, `.planning/workstreams/gouvernance/STATE.md` § Dette.
- **Critère RGPD** (absorbé : « Revue de fond des grilles de quality-gate-client et content-clarity-judge (motif 3, D-08) », 2026-09-25). RGPD n'apparaît qu'à l'étape « lis le CLAUDE.md » (l.49 de `quality-gate-client`, l.46 de `content-clarity-judge`), dans aucun tableau de rubrique, contrairement à `growth-quality-judge` (critère 2, éliminatoire). Piste : critère RGPD explicite, avec pondération et statut éliminatoire le cas échéant, sur le modèle de ce critère 2.

**Déclencheur de reprise :** la revue code owner de Samuel sur `design-orchestrator` (D-12), la prochaine mission dev qui exerce l'étage implémentation croisée avec `vf-design-judge`, la prochaine revue de fond des grilles des juges business et content, ou un manquement RGPD qui n'a pas fait baisser le score d'un livrable jugé.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## A2 — collision de nom entre scripts de modules non détectée à l'installation — DIFFÉRÉ (2026-09-25) — CLOS (2026-10-16) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Écart D-08(b) — digest du manager sans interdits du lab sur le chemin vf-dev-manager → vf-design-judge — DIFFÉRÉ (2026-09-25) — CLOS (2026-11-05, fusionné dans Juges et digests D-08) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Revue de fond des grilles de quality-gate-client et content-clarity-judge (motif 3, D-08) — DIFFÉRÉ (2026-09-25) — CLOS (2026-11-05, fusionné dans Juges et digests D-08) -->
## Ramener le socle du bootstrap sous 2 000 tokens (ADR-029) — DIFFÉRÉ (2026-09-26)

**Capturé :** 2026-09-26, planification de la Phase 43 (compartiment `gouvernance`, checkpoint de
`43-04-PLAN.md`). Décision : option « ratchet-socle », décision déléguée par Willy au head
(/vf-decide), AskUserQuestion session principale, 2026-09-26. La mesure du jour devient une ligne
de baseline `@bootstrap:socle` et toute hausse bloque. Le plafond ADR-029 n'est pas atteint : il
reste un objectif.

**Le défaut :** le socle minimal d'un lab (fermeture `resolve-deps.sh conductor` + skill installer
+ commandes du plugin) mesure **≈ 2 499 tokens** (9 997 octets des lignes `name`/`description`/
`when_to_use` sous `LC_ALL=C`, ÷ 4 ; mesure du 2026-09-26, estimation du plan 43-04) pour un
plafond de 2 000. Composition mesurée, sept modules de la fermeture plus deux autres sources :

| Source | Octets | Tokens |
|---|---|---|
| conductor (vf-calibrate 1070, vf-new-lab 1174, vf-update 953, vf-notify 796) | 3 993 | 998 |
| planning-core | 1 075 | 269 |
| skill-creator (skill-creator-workflow 674, skill-creator 355) | 1 029 | 257 |
| consolidator | 884 | 221 |
| audit-architecture | 818 | 205 |
| infrastructure-audit | 487 | 122 |
| validator (aucun SKILL.md) | 0 | 0 |
| installer (skill exposé, sans `module.json`) | 535 | 134 |
| 7 commandes `plugin/commands/*.md` | 1 176 | 294 |

**Piste de fix :** retirer environ 500 tokens (≈ 2 000 octets) de descriptions. Les descriptions
sont le mécanisme de déclenchement des skills : chaque coupe se relit contre son effet sur le
routage. Cibles les plus rentables : conductor, puis planning-core. Chaque coupe fait baisser la
ligne de baseline, et une baisse n'exige pas de citation.

**Déclencheur de reprise :** exécution de la Phase 43 terminée (la ligne de baseline existe), ou
tout ajout de skill au socle qui ferait rougir le ratchet.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## FAUX VERT possible de `inject-mcp-tools.sh -verify` sur un dossier mixte — DIFFÉRÉ (2026-09-26) — CLOS (2026-10-16) -->
## Référencer recalc-planning.sh / modele-cycles.md depuis le SKILL.md de planning-core — reporté (2026-09-28)

**Capturé :** 2026-09-28, correction ciblée lot 2 de la Phase 44 (`.planning/workstreams/gouvernance/phases/VFDO-44-…`). Décision : « décision du head sous délégation technique de Willy, session principale, 2026-09-28 », lot 2 L3.

**Le point** : `plugin/planning-core/SKILL.md` ne référence encore ni `scripts/recalc-planning.sh`
ni `references/modele-cycles.md` — le moteur de recalcul d'état par cycles livré en Phase 44 n'est
donc découvrable par aucun skill.

**Motif du report** : P44-D-01e — `SKILL.md` reste intentionnellement intact en Phase 44 ; la
commande n'est câblée nulle part (aucun hook, aucune gate) avant les Phases 45/48. Câbler la
référence avant le câblage réel produirait une doc qui pointe vers une commande sans appelant.

**Déclencheur de reprise :** Phase 48 (ou la phase qui câble effectivement `recalc-planning.sh` à
un déclencheur).

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-09-30.md — ## Pour Samuel — hooks GSD introuvables dans les worktrees (constaté 2026-09-28) — CLOS (Phase 41.3, 2026-09-30) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Pour Samuel — faux rouge local de `test-vibeflow-update.sh` sur `~/.claude/skills/synced/` réécrit par le runtime (constaté 2026-09-28) — CLOS (2026-10-16) -->
## guard-driver-lock.sh sous EnterWorktree vise le checkout principal — OUVERTE pour les labs plats, absorbée pour les labs partitionnés (Phase 57, 2026-10-10)

**Constat :** sous EnterWorktree, `guard-driver-lock.sh` vise le checkout principal, non le
worktree. `.worktreeinclude` (Phase 41.3, plan 02) y recopie `.claude/scripts/` mais ne corrige pas
cette résolution : hors périmètre, non traité. **Déclencheur de reprise :** un verrou de driver lu
ou posé au mauvais endroit depuis un worktree.

**Labs partitionnés :** absorbée par la Phase 57 — le guard et `driver-lock.sh` résolvent les
verrous sous `git rev-parse --git-common-dir`, partagés par les worktrees du clone (P57-D-07,
P57-D-08). **Labs plats :** reste ouverte, aucun changement de comportement (P57-D-03) ;
déclencheur de reprise inchangé.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-10-16.md — ## Pour Samuel — `vf_ws_enumerate` pose `found=1` même quand `cd` échoue (constaté 2026-09-28) — CLOS (2026-10-16) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Pour Samuel — `vf_ws_enumerate` ne restitue pas fidèlement un compartiment à saut de ligne — CLOS (2026-11-05, fusionné dans Classe gate qui conclut sans juger) -->
## Garde de fin de geste : objet antérieur imputé à la session et résidus de la Phase 41.3 — DIFFÉRÉ (2026-11-05)

**Fusion du 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F2). Texte intégral des sujets absorbés : `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`, aux titres cités. Priorité P2 : chaque blocage à tort coûte un tour de session.

**Imputation d'un objet antérieur** (absorbé : « `guard-fin-de-geste.sh` impute à la session un objet antérieur qui change d'état », 2026-11-03, demande de Samuel).
- **Cause, mesurée :** l'attribution (M3) compare des lignes de verdict de `check-method-budget.sh` (`comm -23 "$NOW" "$SNAP"`, sortie filtrée par `jetons()`), pas l'existence des objets. Une branche intégrée pendant la session fait apparaître une ligne `RANGEABLE … déjà intégrée dans origin/main`, imputée à la session.
- **Conséquence :** le Stop bloque sur des objets que la session ne doit pas supprimer (worktrees `v2-cockpit` et `etude-floorplan`, d'autres sessions) ; le coupe-circuit à 3 blocages borne le coût.
- **Piste :** que le snapshot enregistre l'identité des objets (chemins de worktrees, noms de branches locales, SHA de stashes, chemins de mémoires) et n'impute un verdict `RANGEABLE` que si son objet n'existait pas au démarrage. Témoin rouge : un worktree présent au snapshot dont la branche est intégrée pendant la session, aucun blocage ; il rougit aujourd'hui.
- **Source :** `plugin/conductor/scripts/guard-fin-de-geste.sh` (copie posée dans `~/.claude/scripts/`). Correctif = PR plus release patch. Aucun commit sur ce fichier depuis le 2026-11-03 (constat du 2026-11-05).

**Résidus de la Phase 41.3** (absorbé : « Résidus de la Phase 41.3 (revue finale, tour 3) », 2026-09-30, décision du manager). Lignes à re-mesurer avant correction.
- (1) Snapshot de mission unique par dépôt, écrasé par une mission concurrente (`check-mission-exit.sh:184`) : E7 rend SAIN sur le snapshot d'une autre mission quand le verrou est relâché.
- (2) Avis d'archivage perdu si la session s'arrête après un Stop bloquant, ou si l'écriture de `.now` échoue après archivage (`guard-fin-de-geste.sh:142`).
- (3) Snapshot de session pris sans `--auto --dry-run` (`guard-fin-de-geste.sh:126`) : un refus préexistant est rapporté comme neuf.

**Ce qui tombe de l'ancienne entrée :** (4) LIVRÉ, entrées CHANGELOG `conductor` `[v1.46.0]` et `dev-orchestrator` `[v2.26.0]`, toutes deux « Phase 41.3 » ; (5) le tri du BACKLOG et du ROADMAP `fiabilite` se fait au tri du 2026-11-05, et `check-method-budget.sh` le constate par machine ; (6) STATE `gouvernance` à 21 Ko, compartiment de Willy, constat machine aussi. Aucun des trois n'a plus besoin d'une entrée.

**Déclencheur de reprise :** la prochaine reprise de la garde de fin de geste, ou un nouveau blocage à tort.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Résidus de la Phase 41.3 (revue finale, tour 3) — DIFFÉRÉ (2026-09-30) — CLOS (2026-11-05, fusionné dans Garde de fin de geste) -->
## Recette réelle de `/vf-split-planning` en session interactive (réserve WSCH-01) — DIFFÉRÉ (2026-10-08)

**Origine :** `41.2-VERIFICATION.md` est resté en `human_needed` (5/6). Le contrat écrit du skill est prouvé par
`test-vf-split-planning.sh`, mais personne n'a vérifié qu'un agent pose bien la question à la fin de l'initialisation
d'un lab, ni le repli en sous-agent. WSCH-01 a été coché avec cette réserve à la clôture de `fiabilite-v1.0`
(arbitrage Samuel, AskUserQuestion session principale, 2026-10-08 : « Dette tracée, on clôt »).

**Geste attendu :** sur un lab jetable fraîchement initialisé, lancer `/vf-split-planning`, observer la question,
répondre « non » (planning unique, aucun appel au geste), puis rejouer le même parcours en sous-agent, où
AskUserQuestion n'est pas disponible. Consigner le résultat dans `41.2-VERIFICATION.md`.

**Déclencheur de reprise :** la prochaine initialisation réelle d'un lab de code, ou une évolution de `vf-split-planning`
ou de `vf-new-lab`.

## Mineurs des juges des releases v2.73.0 et v2.74.0 (`check-prd.sh`, `check-phase-validation.sh`, `vf-validation.sh`, `check-architecture.sh`, `vf-divergence-hook.sh`) — DIFFÉRÉ (2026-11-05)

**Fusion du 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F3). Même origine (juges frais des Phases 59, 60, 61), même déclencheur « prochaine évolution du fichier ». Mineurs, non bloquants, tracés, non corrigés ; aucun commit sur ces fichiers après `9d59a2d8` (constat du 2026-11-05). Texte intégral des trois sujets absorbés : `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`, aux titres « Mineurs laissés par les juges de la release v2.73.0 — `check-prd.sh` (bundle produit) », « … v2.74.0 — `check-phase-validation.sh`, `vf-validation.sh`, `check-architecture.sh` » et « … v2.74.0 — `vf-divergence-hook.sh` ». Lignes à re-mesurer avant correction.

**`plugin/product-team-bundle/scripts/check-prd.sh` (v2.73.0, Phase 59)**
- Faux rouge quand le texte du gabarit sert d'amorce à une vraie réponse : `tmplword` cherche une sous-chaîne (`index(t, T[i])`, `:190-192`).
- Titre de rubrique BRIEF apparié par préfixe : « Problématique de stockage » compte comme Problème (`index(lab, "probl") == 1`, `:421`).
- `--requirements` passé deux fois : la dernière valeur gagne en silence (`:111-115`, sans garde comme `check-architecture.sh:77`).
- Sous-puce `  - **REQ-03** dépend de lui` rend le code 3 : faux rouge sur une liste de dépendances (`:50-58`).

**`plugin/conductor/scripts/` : `check-phase-validation.sh`, `vf-validation.sh`, `check-architecture.sh` (v2.74.0, Phases 60 et 61)**
- Suffixe collé après un id décimal ou à lettre (`60.1x`) : « introuvable » alors que gsd résout, contre la promesse du README (`check-phase-validation.sh:121-135` et `:456-472`).
- Faux rouge conservateur `60-1`, `AUTH-2` : 64 au lieu de 3 (`check-phase-validation.sh:460`).
- Tolérance au préfixe (`phase-60`, `ZZ-60` lus comme 60) non vérifiée contre `project_code` (`idkey`, `:132-135`).
- Marqueur `**Validation:**` jamais commité, invisible depuis un worktree : inerte tant qu'ADR-059 tient (`vf-validation.sh:461-463`).
- `check-architecture.sh` : faux rouge sur une rubrique dont le corps commence par `[` (`isbody`, `:119`).

**`plugin/conductor/scripts/vf-divergence-hook.sh` (v2.74.0, Phase 61)**
- Refus global au premier hook tiers : un `post-commit` tiers empêche l'armement des deux autres, et `update --all` ne réarme pas (`REFUS hook-tiers`, `:634`).
- Bruit `NON VERIFIABLE` à chaque `commit --amend` quand le cache est purgé (`:306-307`), et ligne manuelle muette jusqu'à `update --all` (même repli).
- Le désarmement lit le dossier résolu par `core.hooksPath`, pas `.git/hooks` (`:241`, `do_disarm` `:671-682`) ; commentaire d'en-tête inexact sur `cherry-pick` (`:130`).

**Déclencheur de reprise :** la prochaine évolution de `check-prd.sh` ou la Phase 63 (`TBD:` admis dans la section des questions ouvertes) ; du marqueur de phase ou de la porte `check-phase-validation` ; du filet de divergence, ou un incident de hook tiers sur un clone réel.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Mineurs laissés par les juges de la release v2.73.0 — `check-prd.sh` (bundle produit) — DIFFÉRÉ (2026-10-29) — CLOS (2026-11-05, fusionné dans Mineurs des juges v2.73 et v2.74) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Mineurs laissés par les juges de la release v2.74.0 — `check-phase-validation.sh`, `vf-validation.sh`, `check-architecture.sh` — DIFFÉRÉ (2026-10-29) — CLOS (2026-11-05, fusionné dans Mineurs des juges v2.73 et v2.74) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Mineurs laissés par les juges de la release v2.74.0 — `vf-divergence-hook.sh` — DIFFÉRÉ (2026-10-29) — CLOS (2026-11-05, fusionné dans Mineurs des juges v2.73 et v2.74) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Réexamen approche C (plateforme collaborative) — 2027-01-31 — DIFFÉRÉ (2026-10-29) — CLOS (2026-11-05, échéance reportée au STATE) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-02.md — ## Installeur et tests `plugin/_internal` sans module dans la carte — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-02) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-02.md — ## `dev-orchestrator` : 26 500 lignes et responsabilités mêlées — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-02) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-02.md — ## Gates de `dev-orchestrator` à rejouer sur témoin rouge — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-02) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Choix de la langue de l'interface du cockpit (français / anglais) — DIFFÉRÉ (2026-11-01) — CLOS (2026-11-05, devenu SEED-005) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Cockpit en largeur mobile et clarté de la visite guidée — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-05, livré PR #200) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Commande `/vf-recette` — recette humaine pas à pas — DIFFÉRÉ (2026-11-02) — CLOS (2026-11-05, abandonné) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Cockpit : « Où en est-on ? » sur un lab sans STATE rend des champs vides — DIFFÉRÉ (2026-11-03) — CLOS (2026-11-05, livré PR #200) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Cockpit : anglais résiduel et coquilles du chrome — DIFFÉRÉ (2026-11-03) — CLOS (2026-11-05, livré PR #200) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## `guard-fin-de-geste.sh` impute à la session un objet antérieur qui change d'état — DIFFÉRÉ (2026-11-03) — CLOS (2026-11-05, fusionné dans Garde de fin de geste) -->
## `/vf-update` ne propose pas un module apparu dans une release — CORRECTIF EN PR (2026-11-05)

**État (2026-11-05) :** correctif en PR, branche `fix/vf-update-nouveaux-modules` (arbitrages BL35-Q1..Q3, BL35-A1..A5, BL35-R5-S1, BL35-R5-S4 : Samuel, AskUserQuestion session principale, 2026-11-05). À clore au merge.

**Priorité : P1** (relevée le 2026-11-05 au tri du planning, constat de l'inventaire, sans arbitrage). La prochaine release groupée publiera tout le travail cockpit des Phases 68 à 71 à des postes qui n'ont pas le module ; même famille que l'issue #188 (volet 1) : « `/vf-update` ne voit pas un retard ou une nouveauté de module ». À traiter avant la release groupée. Aucun commit sur `plugin/conductor/skills/vf-update/SKILL.md` ni sur `plugin/_internal/vibeflow-update.sh` depuis le 2026-11-03.

**Origine :** session principale du 2026-11-03. Après avoir mis VibeFlow en v2.75.0, Samuel n'a pas `/vf-cockpit`. Inscription demandée par Samuel, avec un correctif après la planification de la Phase 69 (session principale Claude Code, 2026-11-03).
- **Constat, mesuré :** le plugin 2.75.0 est bien dans le cache (`~/.claude/plugins/cache/vibeflow-os/vibeflow/2.75.0/`), mais le registre `~/.claude/scripts/.vibeflow-installed` liste 13 modules sans `cockpit`. `/vf-update` ne met à jour que les modules déjà inscrits au registre et ne dit rien des modules du catalogue qui n'y sont pas.
- **Conséquence :** un module livré dans une release reste invisible pour les utilisateurs existants. Il n'arrive que par un `/vibeflow-install` qu'ils n'ont aucune raison de relancer.
- **Piste :** en fin de `/vf-update`, comparer les modules du catalogue de la version posée à ceux du registre et proposer les nouveaux, sous confirmation, jamais installés d'office. Il ne faut pas reproposer un module que l'utilisateur a retiré exprès. Témoin rouge : un registre sans `cockpit` face au catalogue v2.75.0 → aucune proposition aujourd'hui.
- **Source :** `plugin/conductor/skills/vf-update/SKILL.md` et `plugin/_internal/vibeflow-update.sh`. Correctif = PR plus release patch.

**Déclencheur de reprise :** juste après la planification de la Phase 69 (demande de Samuel, session principale Claude Code, 2026-11-03).

## Cockpit : mineurs d'affichage et sécurité basse (R8, carte Session, N4, N6, goût de la 71, H1-b) — DIFFÉRÉ (2026-11-05)

**Fusion du 2026-11-05** (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 : « Les 6 fusions (Recommandé) », F1). Texte intégral des sujets absorbés : `.planning/archives/backlog/racine-BACKLOG-2026-11-05.md`, au titre cité. Rien n'est corrigé ici ; chaque ligne garde sa preuve (re-mesurée le 2026-11-05) et son déclencheur. Priorité P2.

- **R8 de la recette de la Phase 68** (absorbé : « R8 de la recette de la Phase 68 : le panneau latéral ne dit pas l'état de la mission », 2026-11-04, P70-D-24). Le panneau ne dit pas l'état de la mission ; un nœud en cours a le même point qu'un nœud fait. Déclencheur du report rempli (PR #199 mergée le 2026-11-04), aucun commit R8 depuis. Preuve : `plugin/cockpit/scripts/vf-cockpit-project.mjs:107` (le résumé dit seulement « N nœuds, M faits »).
- **Carte « Session » de l'onglet Équipe** (absorbé : « Carte « Session » de l'onglet Équipe : pied « en attente », badge « En cours » », 2026-11-04, `70-RECETTE-JUGES.md`). Défaut de la 69 révélé par la 70. Preuve : `plugin/cockpit/skills/cockpit-moteur/assets/ui/72-vf-equipe.js:140`, `x.st = w.etat === 'termine' ? 'done' : 'active'` : tout état autre que « terminé » devient actif. Témoin rouge : une session en attente rend le badge « En cours ».
- **N4** (absorbé : « Écarts de recette de la Phase 68 reportés au BACKLOG (N4, N5, N6) », 2026-11-04, P68-D-38). Le panneau Phase affiche « Ligne de ROADMAP : … » avec le markdown `**` brut. Preuve : `plugin/cockpit/scripts/vf-cockpit-planning.mjs:39` garde `line: m[3]` brut. N5 est LIVRÉ (PR #202, `a6912f25`, cockpit v1.2.1) : il sort d'ici.
- **N6** (même entrée). Hors d'une branche `feat/phase-N`, une mission abandonnée n'apparaît nulle part dans la pane vf-signal, alors que la carte Projet du cockpit web la montre. Non re-sondé le 2026-11-05.
- **Goût résiduel de la 71** (non tracé au BACKLOG jusqu'ici ; `71-RECETTE-HUMAINE.md:232-233`, PR #203 « Goût résiduel »). Cartes à 0,29 en 1280×720 tiroir ouvert ; « Terminé » face à « Python 3 introuvable » (`plugin/cockpit/scripts/vf-cockpit-terminal-tiroir.mjs:17`, `termine: 'Terminé'`). Aucun commit de rendu après `d4171ded` ; sans capture, pas de preuve visuelle ; point de goût à faire confirmer.
- **`shell_sous` sans attente bornée** (mineur de la PR #204, « tracé, non corrigé »). `plugin/cockpit/scripts/tests/test-cockpit-terminal-session.sh:101` : une seule passe `pgrep`, pas de boucle.
- **Libellé « écrit à un agent »** (arbitré P70-D-23, option 2a, `70-RECETTE-JUGES.md:67-70` ; livré conforme, `vf-cockpit-who.mjs:71-73`). Résidu possible : le rôle ne se résout que parmi les sous-agents (`rolesDe`), donc un message vers la session principale s'affiche « un agent ». Point de goût à faire confirmer.
- **H1-b, sécurité basse** (hérité de `main`, mandat H-1, `71-SECURITY.md:300,320`). `sous()` de `plugin/cockpit/scripts/vf-cockpit-env.mjs:12` laisse passer un dossier nommé `..xxx` : `!r.startsWith('..')` traite `<lab>/..xxx` comme hors du lab.

**Déclencheur de reprise :** la prochaine passe sur l'affichage du cockpit ou de la pane vf-signal ; H1-b, la prochaine modification de `vf-cockpit-env.mjs`.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## R8 de la recette de la Phase 68 : le panneau latéral ne dit pas l'état de la mission — DIFFÉRÉ (2026-11-04) — CLOS (2026-11-05, fusionné dans Cockpit mineurs d'affichage et sécurité basse) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Carte « Session » de l'onglet Équipe : pied « en attente », badge « En cours » — DIFFÉRÉ (2026-11-04) — CLOS (2026-11-05, fusionné dans Cockpit mineurs d'affichage et sécurité basse) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## `scripts/check-machine-paths.sh` : vert sous macOS, rouge sous Linux — DIFFÉRÉ (2026-11-04) — CLOS (2026-11-05, fusionné dans Classe gate qui conclut sans juger) -->
<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-05.md — ## Écarts de recette de la Phase 68 reportés au BACKLOG (N4, N5, N6) — DIFFÉRÉ (2026-11-04) — CLOS (2026-11-05, fusionné dans Cockpit mineurs d'affichage et sécurité basse) -->

## Cockpit : plusieurs terminaux — DIFFÉRÉ (2026-11-05)

**Priorité : non fixée.** Entrée non cadrée, à cadrer avec la Phase 72 ou après.

**Origine :** demande de Samuel, session principale Claude Code, 2026-11-05, mot pour mot : « Je pense que pour le soucis "un seul terminal" devrait etre améliorer, pour l'instant c'est bien mais il faudrait pouvoir en ouvrir plusieurs ».
- **Constat :** aujourd'hui, il n'y a qu'une session de terminal par serveur du cockpit ; une seconde est refusée (`plugin/cockpit/README.md`, § terminal). Le secret de session reste lié à l'onglet qui a échangé le jeton d'amorçage (même README, § jeton d'amorçage) : un second onglet n'a aucun moyen de s'y rattacher.
- **Piste :** aucune arrêtée. Le cadrage devra dire comment plusieurs sessions coexistent (une par onglet, ou plusieurs dans le même tiroir), et ce que devient le modèle d'amorçage à usage unique et de secret par onglet.

**Déclencheur de reprise :** le cadrage de la Phase 72, ou la prochaine passe sur le terminal du cockpit.

## Hook `SubagentStop` : bloquer la fin d'un agent tant que `background_tasks` n'est pas vide — DIFFÉRÉ (2026-11-05)

**Priorité : non fixée.** Spike puis phase.

**Origine :** arbitrage Samuel, AskUserQuestion session principale, 2026-11-05, « Plus tard, en spike » (A2 du mandat du correctif des workers orphelins). La règle écrite (`plugin/conductor/references/team-kernel.md` § Fin de tour inerte) ne garantit rien à la machine : un hook ferait la garantie.
- **Piste :** un hook `SubagentStop` qui refuse la fin d'un agent tant que `background_tasks` n'est pas vide.
- **Deux points NON vérifiés :** (1) la forme plugin — `hooks.json`, ou les hooks de frontmatter sont-ils ignorés pour les agents de plugin ? (2) le plafond de 8 continuations consécutives (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`) : que devient un agent qui l'atteint ?

**Déclencheur de reprise :** le spike, avant toute phase ; ou un nouvel orphelin malgré la règle de fin de tour inerte.

## Cockpit : un script de la page Projet peut piloter le chat (`POST /api/ask`) — SURFACE DES PHASES 69-70, HORS PHASE 72 (2026-11-06)

**Priorité : non fixée.** À vérifier avant toute décision.

**Origine :** signalé par la Phase 72 (audit F-1) ; décision de ne pas le traiter dans la phase, sur ordonnancement de la session principale du 2026-11-06.
- **Observé (lecture du code, sondes d'audit du lot 2 de la Phase 72) :** un script qui s'exécute dans la page Projet peut piloter le chat du cockpit : `POST /api/ask` est accepté avec le jeton de la page (`plugin/cockpit/scripts/vf-cockpit-server.mjs`, vers la l.113). Ce chat tourne en `dontAsk`, avec `--tools Read,Grep,Glob,Bash` et une liste blanche `--allowedTools` (`plugin/cockpit/scripts/vf-cockpit-agent.mjs`, vers les l.14-16).
- **NON vérifié :** le contenu exact de la liste blanche Bash et ce qu'elle permet ; l'exécution réelle d'une commande par un chat piloté par script ; l'existence d'autres gardes.

**Renvoi (2026-11-11) :** AUDC-A-01 et AUDC-B-02, fait (2026-11-11) : la reprise de session est bornée aux identifiants que le serveur a rendus et le débit à deux exécutions (429 au-delà). Le pilotage par un script de la page reste ouvert.

**Déclencheur de reprise :** une passe de sécurité sur le chat du cockpit, ou toute phase qui touche `POST /api/ask`.

<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-2026-11-11.md — ## Cockpit : le `claude` lancé depuis le terminal reçoit `CLAUDE_EFFORT` et `CLAUDE_PID` de la session parente — NON VÉRIFIÉ (2026-11-06) — CLOS (2026-11-11, AUDC-B-06) -->
## Cockpit : une proposition qui ouvre le tiroir pendant que le focus est dans la barre de question range la barre (`#ask-input`) — UX MINEURE (2026-11-06)

**Priorité : non fixée.** Aucune fuite.

**Origine :** recette par juge de la Phase 72, 2026-11-06.
- **Observé :** quand le tiroir s'ouvre automatiquement sur une proposition alors que le focus est dans la barre de question (`#ask-input`), la barre se range (comportement de la Phase 71). Le focus tombe sur `BODY` et les frappes sont perdues, sans aller au cadre ni au shell.
- **NON vérifié :** les autres éléments de la page qui se rangent à l'ouverture du tiroir.

**Déclencheur de reprise :** une passe sur l'ouverture automatique du tiroir.

## Cockpit : points de fusion 71.5 × 72 laissés en place à la release v2.76.0 (`vf-lancer-style`, replis `var(--sp-N, px)`, id `P27` en double) — DIFFÉRÉ (2026-11-06)

**Priorité : basse.** Aucun effet visible : le rendu de la branche assemblée a été recetté et validé par Samuel (message direct en session principale, 2026-11-06 : « c'est parfait on valide. On garde ca en release. »).

**Origine :** relevé de clôture de la Phase 72 (`72-BRANCHEMENTS-MERGE.md` §6) et relecture des résolutions de merge de la release v2.76.0 (2026-11-06).
- **Laissé en place :** la feuille `<style id="vf-lancer-style">` posée à l'exécution par `poserStyleProposition` (`plugin/cockpit/scripts/vf-cockpit-terminal-vue.mjs`), à fondre dans `vf-cockpit-terminal-style.mjs` ; les deux replis `var(--sp-N, <px>)` de `vf-cockpit-lancer-style.mjs`, à retirer maintenant que les jetons d'espacement de la 71.5 sont fusionnés.
- **Motif du report :** la mission de release n'admettait ce rangement que s'il était prouvé sans effet de rendu (captures avant/après identiques sur tous les états du bandeau de proposition) ; une autre branche partie du même commit (`feat/cockpit-retours-utilisateurs`) travaillait au même moment sur la zone basse du cockpit, le rangement y aurait créé des conflits.
- **Id de patch en double :** dans `plugin/cockpit/skills/cockpit-moteur/VENDORED.txt`, `P27` désigne à la fois la garde `VF_COCKPIT_GIT_DURCI` de `scripts/lib/common.mjs` (Phase 78) et les patches d'espacement de la 71.5 (sept lignes) : chaque branche a pris le numéro suivant sans connaître l'autre. Ambiguïté documentaire seule, aucun gate connu ne lit ces ids (non vérifié).
- **Affirmation héritée :** le README et le CHANGELOG du module disent que le calcul de l'arbre « sale » est reporté à la Phase 78 ; la 78 est fusionnée sans l'avoir câblé (`AVERTISSEMENTS_RESERVES` reste inactif). `LANC-12` est encore « Pending » dans `REQUIREMENTS.md` alors que la 72 est à 16/16 plans (identique au parent de la 72).

**Déclencheur de reprise :** la prochaine phase qui touche le bandeau de proposition ou le style du terminal, après la fusion de `feat/cockpit-retours-utilisateurs`.

## Verrou de driver par phase : trois mineurs de la relecture adverse de la release v2.76.0 — DIFFÉRÉ (2026-11-06)

**Priorité : basse.** Aucun verrou orphelin observé ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-06 (relayé par la session principale) : au BACKLOG.

**Origine :** relecture adverse SOBR-04 de la release v2.76.0 (volet hors cockpit, SHA `f0bbcf4c`).
- **Graphie du numéro de phase :** `driver-lock.sh` (`vf_dl_phase_valid`, dossier `phases/<N>`) accepte `--phase=41.1` puis `--phase=041.1` comme deux verrous distincts, alors que `phase_covers` de `guard-driver-lock.sh` les tient pour équivalents. Sondé : deux `acquire` rendus `acquired: true`. Propriété attendue : le numéro est normalisé avant de nommer le dossier.
- **Dossier vide :** `phases/<N>/` reste vide sous `.git/vf-driver/ws/<ws>/` après `release`. Inoffensif (`status --all`, le guard et la sonde de hiérarchie le tolèrent).
- **Versions mixtes :** un `driver-lock.sh` de v2.75.1 ignore les verrous de phase et accorde le verrou de compartiment pendant qu'une phase est tenue. Ne vaut que si deux sessions d'un même dépôt n'ont pas la même version du plugin.

**Déclencheur de reprise :** la prochaine phase qui touche `driver-lock.sh` ou `guard-driver-lock.sh`.

## Mod vf-signal : version minimale de Claude Code pour ses hooks — NON MESURÉ (2026-11-06)

**Priorité : basse.** Arbitrage Samuel, AskUserQuestion session principale, 2026-11-06 (relayé par la session principale) : « Noter et reporter » — la release v2.76.0 dit seulement « mesuré sur Claude Code 2.1.319 ».

**Origine :** relecture adverse SOBR-04 de la release v2.76.0 (volet cockpit, SHA `f0bbcf4c`).
- **Observé :** `plugin/.claude-plugin/plugin.json` déclare `hooks: ./cockpit/signal/hooks/hooks.json`, au format `{modules:[...]}` ; `claude plugin validate plugin` passe sur Claude Code 2.1.319.
- **NON mesuré :** le comportement d'un Claude Code plus ancien (fichier de hooks refusé, plugin entier refusé, ou hooks seuls ignorés) ; aucune version minimale n'est écrite pour le mod.

**Déclencheur de reprise :** un utilisateur sur une version ancienne de Claude Code, ou la prochaine phase qui touche le mod vf-signal. Mesure dans un `HOME` jetable avec une version ancienne installée à part.

## Cockpit : seconde vague de PU-G-015 et PU-G-133 (part Équipe) — DIFFÉRÉ (2026-11-07)

**Priorité : basse.** Aucune fuite ; réglages d'usage relevés par le panel utilisateurs (`.planning/missions/2026-11-06-panel-utilisateurs-GLOBAL.md`).

**Origine :** jointure des retours du panel utilisateurs du cockpit, 2026-11-07.
- **PU-G-015 (part equipe-git) :** `70-vf-live.js` doit fermer les menus du moteur quand « Au travail » s'ouvre, et « Au travail » doit se fermer sur un événement envoyé par le moteur. Non fait : les deux parts de la proposition chevauchent le moteur et la coque.
- **PU-G-133 :** le nom de session est dérivable sans risque dans `vf-cockpit-equipe-carte.mjs` (environ deux lignes de la ligne « Lancée depuis la carte », une fois que `lancer-suivi` enregistre le nom). Afficher le mode de permission toucherait P72-D-20 (le mode vit dans un fichier tenu par le terminal, illisible par la page) : **décision de Samuel**, recommandation « nom seul ».

**Déclencheur de reprise :** la prochaine phase qui touche `70-vf-live.js` ou la carte « Lancée depuis la carte ».

## Cockpit : entrée « Clic droit » du menu et libellés de `viewer.html` (PU-G-110) — DIFFÉRÉ (2026-11-07)

**Priorité : basse.**

**Origine :** retours du panel utilisateurs, groupe projet et lancement, 2026-11-07.
- **PU-G-110 :** l'entrée du menu clic droit est un point d'extension de `viewer.html` (moteur vendorisé), hors de portée d'un lot qui ne le patche pas ; la remontée sous le titre est faite, pas l'entrée du menu.

**Déclencheur de reprise :** la prochaine synchro du moteur (`amont/SYNCHRO.md`) ou un patch de `viewer.html`.

## Cockpit : synchronisation complète des états de lancement — annulée, expirée, remplacée (PU-G-113) — DIFFÉRÉ (2026-11-07)

**Priorité : non fixée.**

**Origine :** retours du panel utilisateurs, lot 8 lancer et bandeau, 2026-11-07.
- **Fait :** « Lancée » n'apparaît plus sans signal (« Préparée depuis la carte. »), et le message d'envoi est borné à 120 s.
- **Non fait :** suivre l'état annulée, expirée, remplacée jusqu'à la carte. Cela exige de toucher `vf-cockpit-lancer.mjs` ou `lancer-suivi.mjs`, ou de créer un nouveau canal.

**Renvoi (2026-11-11) :** AUDC-M11, fait (2026-11-11) : seule l'annulation est traitée (statut remis à zéro, annonce vidée) ; expirée et remplacée restent ouvertes.

**Déclencheur de reprise :** la prochaine phase qui touche le suivi des lancements.

## Cockpit : résumé en langage courant (PU-G-104) et titres de santé à variables (PU-G-080 part C) — DIFFÉRÉ (2026-11-07)

**Priorité : basse.**

**Origine :** retours du panel utilisateurs, 2026-11-07.
- **PU-G-104 :** le repli « Détails techniques » est fait ; le **résumé en langage courant** n'a aucune source dans les données du cockpit.
- **PU-G-080 part C :** environ 25 titres à variables dans `plugin/cockpit/skills/cockpit-moteur/assets/lib/health.mjs` (17 sites) restent en anglais. Le pied de la santé et les titres fixes sont traduits ; il faut des clés à `{}` au dictionnaire et traduire les phrases au moment de l'assemblage.

**Déclencheur de reprise :** la prochaine passe sur le panneau Santé ou sur le dictionnaire.

## Cockpit : classes C de l'onglet Équipe et du tiroir Git (195, 007, 202, 168) — DIFFÉRÉ (2026-11-07)

**Priorité : basse.** Nouvelles interactions, jamais des réglages.

**Origine :** retours du panel utilisateurs, groupe équipe-git, 2026-11-07.
- **PU-G-195 :** tiroir Git élargissable (l'étiquette complète au survol est faite).
- **PU-G-007 :** libellé visible sur chaque icône dès 1 000 px (la part compatible est faite).
- **PU-G-202, PU-G-168 :** non faites, hors lots ; à relire dans le registre.

**Renvoi (2026-11-11) :** PU-G-202 : AUDC-M9, fait (2026-11-11) pour la coupure du serveur (« Direct coupé » à 5 s) ; PU-G-168 : AUDC-M4, PU-G-007 : AUDC-M5, PU-G-195 : AUDC-M12, ouverts (Phases 74 et 80).

**Déclencheur de reprise :** une demande d'utilisateur sur l'un de ces points.

## Cockpit : état « bloqué » du tiroir « Au travail » sans source (contrat `who@2`) — DIFFÉRÉ (2026-11-07)

**Priorité : basse.**

**Origine :** diagnostic DG-06 du panel utilisateurs, 2026-11-07.
- **Observé :** aucune source ne produit l'état « bloqué » : le contrat `who@2` n'a que actif, en attente, terminé. Le code est resté inerte, sans rien supprimer ; le seul signal de blocage vu est « sans nouvelle depuis … ». Un état « en échec » demanderait une spécification.

**Déclencheur de reprise :** une évolution du contrat `who`.

## Cockpit : deux idées et un temps serveur laissés par le panel (DG-09, DG-11) — DIFFÉRÉ (2026-11-07)

**Priorité : basse.**

**Origine :** diagnostics du panel utilisateurs, 2026-11-07.
- **DG-09 :** l'exclusion de `vf-cockpit-code-vf.mjs` est voulue (`IGNORE`, P67-D-17), close. Idée non faite : un état vide de la recherche qui dit « le planning se lit dans l'onglet Projet ».
- **DG-11 :** « Chargement des actions… » est posé ; le **temps serveur** de `lancer.mjs` reste à mesurer et à réduire.

**Déclencheur de reprise :** la prochaine phase qui touche la recherche ou `lancer.mjs`.

## Cockpit : mineurs de la relecture du groupe projet et lancement, dont deux décisions à prendre — DIFFÉRÉ (2026-11-07)

**Priorité : basse.**

**Origine :** rapport du groupe projet et lancement, retours du panel utilisateurs, 2026-11-07.
- **Espace de fin de ligne** à `plugin/cockpit/scripts/vf-cockpit-terminal-client.mjs:127`.
- **Couleurs système** absentes de la liste noire de LB.S4 (`test-cockpit-lancer-bandeau.sh`).
- **`keypress` hors Chromium** : la retenue de l'Entrée tenue n'est sondée que sous Chromium.
- **Point 158 :** `current_phase` entre parenthèses dans un message de règle, gardé (c'est le nom du champ à écrire dans `STATE.md`).
- **Quatre px sans variable** (12,5 px deux fois, 44 px, 560 px, 240 px), listés en exceptions nommées dans LB.S4 : **à Samuel de dire s'il amende la règle R3 de la Phase 72.**
- **`ui/40-tour.js` à 298 lignes**, au seuil de 300 lignes : le prochain ajout le dépasse.

**Déclencheur de reprise :** la prochaine phase qui touche le terminal, LB.S4 ou la visite.

## Cockpit : résiduels de la Phase 72 jamais consignés (course `lstat`, temporaires après SIGKILL, points de goût) — DIFFÉRÉ (2026-11-07)

**Priorité : basse.**

**Origine :** `.planning/missions/2026-11-05-phase-72-lancer-depuis-cartes.md`, sections « Consignés, non corrigés » et « Points de goût pour Samuel » ; contrôle fait le 2026-11-07 contre ce fichier.
- **Course `lstat`/ouverture** sur le dossier support du mode (L1) : consignée par la mission, pas corrigée.
- **Temporaires non balayés après SIGKILL** (S-3) : consignés par la mission, pas corrigés.
- **Points de goût :** intentions en ASCII sans accent (alphabet fermé de la ligne, voulu) ; bouton principal « Cadrer » désactivé sur une phase finie ; pas de bouton « Lancer » sur la carte (l'action est le verbe) ; message du refus 409 générique (quatre causes indistinguables côté serveur) ; ligne `VFP>` vide ajoutée par le Ctrl-C avant la ligne proposée ; « Lancée » et la récence ne survivent pas à une relance du cockpit (en partie traité par PU-G-113, ci-dessus).

**Déclencheur de reprise :** la prochaine recette de Samuel sur le lancement depuis les cartes.

## Cockpit : sens des liens de phase restant à l'ancienne lecture (suite de PU-G-100) — DIFFÉRÉ (2026-11-07)

**Priorité : basse.** À trancher par Samuel.

**Origine :** jointure des retours du panel utilisateurs, 2026-11-07. PU-G-100 (6b3d90ee) a corrigé le panneau d'une phase et les titres de colonnes de l'onglet Projet ; lien et ordre des cartes inchangés.
- **Reste lu dans l'ancien sens :** le panneau d'un fichier-plan (lien plan vers plan `depends_on`, `plugin/cockpit/scripts/vf-cockpit-project.mjs:130`) liste le prérequis sous « Utilisé par » avec la pastille « Mention » ; l'infobulle d'arête « Phase 1 → Phase 2 · Dépend de » aussi.
- Lectures déjà fausses avant la jointure, hors demande du panel.

**Déclencheur de reprise :** la prochaine passe sur le panneau d'un fichier-plan ou sur les infobulles d'arête.

## Cockpit : titre « Health (security only) » et témoin S5.1 visent un bloc masqué sur Projet (DG-15) — DIFFÉRÉ (2026-11-07)

**Priorité : basse.** À trancher par Samuel : garder ou retirer. Aucune suppression faite.

**Origine :** jointure des retours du panel utilisateurs, 2026-11-07.
- `ui/20-health.js:27` pose « Health (security only) » seulement quand l'onglet est Projet, or DG-15 masque tout le bloc santé sur Projet (`ui/00-vibeflow.js:134`) : ce titre n'est visible nulle part. Sa clé de dictionnaire et le témoin S5.1 de `test-cockpit-sante.sh` visent donc un bloc masqué.

**Déclencheur de reprise :** la prochaine passe sur le panneau Santé ou le dictionnaire.
## Cockpit / équipe : distinguer « attend une tâche de fond » de « terminé » (#223, cause 3)

**Priorité : à arbitrer.** `[cockpit/équipe, #223 cause 3]` Distinguer « attend une tâche de fond » de « terminé » : l'indice transcript (tâche de fond lancée, jamais reprise ni notifiée, dernier message assistant en end_turn) a une précision mesurée d'environ 20 à 40 % (1 vrai positif sur 5, 2026-11-08) et ne dit pas si la tâche tourne ; il faut l'état du registre de tâches du harnais, non exposé dans les transcripts. À reprendre si le harnais l'expose ; sinon indice « tâche de fond sans retour lu » sur lecture de queue bornée, à arbitrer.

## Team-kernel : témoin d'exécution de la doctrine Fin de mandat (#223)

**Priorité : à arbitrer.** `[team-kernel, #223]` Témoin d'exécution de la doctrine Fin de mandat : la garde `test-fin-de-mandat.sh` vérifie que les prompts PORTENT la consigne, pas qu'un worker l'APPLIQUE. Un témoin de comportement (registre driver-lock : enfant fermé sans rapport final, ou `worktree-procs.sh list` non vide au close) reste à concevoir.
## Jalon inscrit sans `gsd-new-milestone` : le STATE ne bascule jamais au démarrage de sa première phase — DIFFÉRÉ (2026-11-03)

**Origine :** session principale du 2026-11-03. Samuel constate que le STATE du compartiment `fiabilite` pointe toujours `equipe-produit-v1.0` avec la Phase 67 « closed ». Inscription demandée par Samuel (session principale Claude Code, 2026-11-03).
- **Constat, mesuré :** sur `main` et sur `feat/phase-69-suivi-travail`, le frontmatter du STATE dit `milestone: equipe-produit-v1.0`, `milestone_name: « l'équipe produit » — Phases 57-66`, `current_phase: 67`. Or la 67 appartient à `vibeflow-v2.0`, et `equipe-produit-v1.0` n'est pas clos (Phases 63 à 66 ouvertes).
- **Cause :** la forme « section de jalon distincte, **sans `gsd-new-milestone`** », posée par `11882c80` (gouvernance-labs, 2026-09-23) puis recopiée pour ECC, equipe-produit et vibeflow-v2.0 (`16387283`), sert à inscrire un jalon **sans le démarrer**, parce que le STATE ne tient qu'une position. Elle ne prévoit pas le geste suivant : basculer le STATE quand une phase de ce jalon démarre vraiment. La 67 a été exécutée, releasée et close sans que personne bascule.
- **Piste :** au démarrage d'une phase (cadrage, plan ou exécution), comparer le jalon de la phase dans le ROADMAP à celui du STATE ; s'ils diffèrent, proposer la bascule (édition à la main du frontmatter, jamais `state record-session`, destructif), jamais d'office. Témoin rouge : un STATE sur `equipe-produit-v1.0` et une phase 69 de `vibeflow-v2.0` qui démarre → aucune alerte aujourd'hui.
- **Correction ponctuelle :** STATE basculé à la main sur `vibeflow-v2.0`, phase 69 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-03 : « vibeflow-v2.0, phase 69 (Recommandé) »), dans la PR qui inscrit les Phases 73 à 77.

**Déclencheur de reprise :** la prochaine inscription d'un jalon, ou la Phase 64 (contrôles branchés en nœuds du plan de bataille).


## Cockpit : limites consignées par le lot 0 de l'audit — DIFFÉRÉ (2026-11-11)

**Origine :** mission « lot 0 de l'audit du cockpit », `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md` (§ « Constats nés de la mission lot 0 »). Décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée. Sécurité décrite par classe, jamais par recette.

### Coupure du serveur sans fermeture de flux (D-M2, AUDC-M9)
**Priorité : moyenne.** Une coupure qui ne ferme pas la connexion (flux muet) n'est pas détectée ; il faut une veille de silence côté page. **Plan :** 79-12 et 79-14 (Phase 79, planifiée le 2026-11-11). **Déclencheur de reprise :** Phase 79.

### Métadonnées des dépôts imbriqués dans l'export (D-M5, AUDC-B-04)
**Priorité : basse.** Branche, tête et worktree d'origine des dépôts imbriqués viennent d'une clé du moteur amont (`meta.repos`) et restent dans l'export. **Déclencheur de reprise :** la prochaine passe sur l'export ou sur le patch du moteur.

### Requête du même site acceptée sur les pages sans jeton (D-M6, AUDC-B-03)
**Priorité : basse.** Le texte de la règle dit « inter-sites » ; une requête du même site est acceptée. **Déclencheur de reprise :** une passe de sécurité sur les pages servies.

### « Server returned 429 » affiché tel quel et session non purgée (D-M7, AUDC-B-02)
**Priorité : basse.** La page montre le message brut du serveur et ne purge pas la session côté page ; non régressif. **Déclencheur de reprise :** Phase 80.

### `stop` et `status` ignorent un serveur orphelin (D-M13, AUDC-H3)
**Priorité : moyenne.** Quand `server.json` est perdu, les deux commandes ne voient pas le serveur resté à l'écoute. **Plan :** 79-06 (Phase 79, planifiée le 2026-11-11). **Déclencheur de reprise :** Phase 79.

### Lien du lab vers un fichier interne protégé (D-M15, AUDC-A-02)
**Priorité : moyenne.** Un lien du lab vers un fichier interne que le serveur protège par ailleurs n'est pas masqué ; hors de la lettre d'AUDC-A-02 (cible dans le lab). **Déclencheur de reprise :** Phase 79, première vague, avec la classe restée ouverte d'AUDC-A-02. **Plan :** 79-07 (Phase 79, planifiée le 2026-11-11).

### Empreinte du code limitée à `serve.mjs` (AUDC-H3)
**Priorité : basse.** La relance compare l'empreinte de `serve.mjs` seul ; un autre module modifié ne remplace pas le serveur. Le port n'est pas comparé. **Plan :** 79-06 (ligne « Lot 0, H3 » du registre ; AUDC-AM4 : 79-06 et 79-16 ; empreinte calculée sur les fichiers de code du module, P79-D-31), Phase 79, planifiée le 2026-11-11. **Déclencheur de reprise :** Phase 79 (serveur lancé depuis le module, AUDC-AM4).

### Formes singulières du repli de lien sans gabarit au dictionnaire (AUDC-H4)
**Priorité : basse.** Lacune préexistante du chrome : certaines formes singulières du texte de repli d'un lien n'ont pas de gabarit au dictionnaire et restent en anglais. **Déclencheur de reprise :** la prochaine passe sur le dictionnaire.

### Lecture passive : pilotes et script shell hors du point unique (AUDC-A-04)
**Priorité : basse.** Les pilotes nommés sont fermés par une liste de sous-commandes de lecture ; un script shell du socle lance git hors du point unique, sans effet mesuré. **Plan :** 79-07 (Phase 79, planifiée le 2026-11-11). **Déclencheur de reprise :** Phase 79, avec AUDC-A-03.

### Sixième onglet qui ne charge plus (AUDC-H1)
**Priorité : moyenne.** Un flux par page ne suffit pas au-delà de six pages ouvertes sur la même origine. **Plan :** 79-14 (ligne AUDC-H1 du registre ; Phase 79, planifiée le 2026-11-11). **Déclencheur de reprise :** Phase 79 (flux partagé entre onglets).

### Tiroir du terminal resté rehaussé après « Annuler » (AUDC-M11)
**Priorité : à arbitrer (goût, pour Samuel).** Après « Annuler », le tiroir garde la hauteur prise pour la proposition. **Déclencheur de reprise :** la prochaine recette de Samuel sur le lancement.


## Cockpit : limites consignées par la Phase 79 — DIFFÉRÉ (2026-11-11)

**Origine :** cadrage de la Phase 79, `.planning/workstreams/fiabilite/phases/VFDO-79-socle-du-cockpit-une-collecte-un-flux-une-route-d-tat/79-CONTEXT.md`. Décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée.

### Chemins absolus dans la route d'état (A38)
**Priorité : moyenne.** `signal.root`, `equipe.root` et `equipe.workers[].cwd` restent des chemins absolus, de forme inchangée depuis la Phase 69, servis par `hello` et par `GET /api/vf/state`. Les masquer change la forme : schéma `@2`. Mots de l'amendement A38 (79-12) : « Limite nommée, inchangée depuis la Phase 69 : `signal.root`, `equipe.root` et `equipe.workers[].cwd` sont des chemins absolus de forme inchangée (C0 « Versions »), servis comme ils le sont déjà par `hello` ; les masquer demanderait un schéma `@2`, hors de cette phase (à verser au BACKLOG par la jointure). » Même sujet que l'entrée « Chemins absolus servis à la page locale » demandée à la jointure : une seule entrée, celle-ci. **Déclencheur de reprise :** la prochaine version de `cockpit-signal` ou de `cockpit-who`.

### Renommage complet des pages et retrait de `vf-cockpit-rename.mjs` (P79-D-08)
**Priorité : basse.** La Phase 79 écrit les noms VibeFlow dans les sources exécutées par Node ; les pages restent renommées comme du texte. Le renommage complet de `viewer.html` et `ui/*.js`, puis le retrait de `vf-cockpit-rename.mjs`, se font en geste séparé. **Déclencheur de reprise :** la fusion de la Phase 80.

### Dernière action limitée à l'arbre principal, lab lui-même worktree lié (A46)
**Priorité : basse.** La dernière action d'un agent (`who`, `doing`) garde sa règle : un fichier d'un worktree hors de l'arbre principal y reste « un fichier hors du lab » ; l'étendre touche le collecteur `who`. Un lab qui est lui-même un worktree lié prend pour arbre principal le premier arbre de git, comme `who`. (Le `nom` de worktree non unique est fermé par défaut dans la phase : deux worktrees vérifiés au même `nom` ne sont pas admis.) **Déclencheur de reprise :** Phase 73 (régie).

### `127.0.0.1` et `localhost` tiennent deux flux (A43)
**Priorité : basse.** Deux origines distinctes : le flux partagé entre onglets ne les réunit pas. **Déclencheur de reprise :** la prochaine passe sur le flux partagé.

### Messages de `serve.mjs` en français sous `?lang=en` (A43)
**Priorité : basse.** Les messages du serveur sont écrits en français à la source et le restent en mode anglais. **Déclencheur de reprise :** la prochaine passe sur `?lang=en`.

### Identifiants de menace à aligner entre les plans de la Phase 79
**Priorité : basse.** Chaque plan numérote ses menaces dans sa propre plage (`T-79-1NN` pour 79-01, plan × 100 + rang) ; l'alignement de la forme entre les 22 plans n'a pas été vérifié à la planification. **Déclencheur de reprise :** l'audit de sécurité de la première vague exécutée.

## Cockpit : réserves consignées par les cadrages des Phases 73, 74, 75, 77 et 80 — DIFFÉRÉ (2026-11-11)

**Origine :** rapports de cadrage `.planning/missions/2026-11-11-phase-73-cadrage.md`, `-74-`, `-75-`, `-77-` et `-80-` (sections « À verser par la jointure »), jointure du 2026-11-11. Décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée, sauf la question P73-Q-01, tranchée plus bas.

### Pastilles « modifiés » du tiroir Git sur fond d'avertissement, en tension avec Q9 (S-1 de la Phase 73, P73-Q-01) — CLOS, SANS OBJET (2026-11-13)
**Priorité : non fixée.** Texte du rapport 73 : « Pastilles « modifiés » du tiroir Git sur fond d'avertissement, en tension avec Q9 (S-1 de la Phase 73). » Le tiroir Git de la Phase 78 pose « modifiés » sur un fond d'avertissement, en tension avec Q9 (« ni fond teinté ») ; la régie de la Phase 73 rend ses propres pastilles neutres (P73-D-10) et ne touche pas le tiroir. **Décision :** arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, réponse : « Les neutraliser (Recommandé) » — option (b) de P73-Q-01 : un correctif du tiroir Git, hors de la Phase 73, porté par l'exécution de la Phase 80. Le rapport 73 est antérieur à cette réponse et dit encore la question « en attente ». **Correction du 2026-11-13 (jointure J1) :** sans objet. La question posée à Samuel était fausse sur les faits (erreur de relais de la session principale) : les pastilles du tiroir Git sont neutres depuis P78-D-33 ; preuve par la Phase 80, segment a (amendement A de 80-06, mutant M-PASTILLE, juge de design). Rien n'est planifié pendant la Phase 80 au titre de cette question ; sa réponse reste citée dans `73-CONTEXT.md`. **Déclencheur de reprise :** aucun.

### Notification du système pour le cockpit (AUDC-I09, part reportée par P73-D-15)
**Priorité : non fixée.** Option éteinte par défaut, trois motifs, texte borné au motif et au nombre ; examen des bornes à faire (texte hors de la page). La Phase 73 livre le titre d'onglet et la pastille de favicon ; l'API de notification du système est reportée. **Déclencheur de reprise :** une demande d'utilisateur de la notification hors de la page, ou la prochaine passe sur le compositeur du titre.

### Coût en devise et limites d'abonnement de 5 h et de 7 jours (Phase 74, P74-D-20, P74-D-24)
**Priorité : non fixée.** Coût en devise au tarif public et limites d'abonnement de 5 h et de 7 jours (relais par la ligne d'état), écartés de la Phase 74 (P74-D-20, P74-D-24 ; questions P74-Q-02, P74-Q-03). La 74 lit le coût en jetons et en durée ; un montant demanderait une table de tarifs tenue à jour dans le module, et la Phase 52 pose « jamais estimé ». Les limites demandent un relais par le script de ligne d'état, hors de ce que lit le socle ; elles restent avec le plafond de coût (AUDC-I35). **Déclencheur de reprise :** le cadrage d'AUDC-I35 (plafond de coût), ou la Phase 52.

### Constats de l'auditeur posés sur les cartes de l'onglet Code (AUDC-I36, troisième idée ; Phase 75, P75-D-19)
**Priorité : non fixée.** `vf-auditer` n'écrit rien sur disque : ses constats ne vivent que dans des transcripts ou en prose dans les `*-SECURITY.md`. **Déclencheur de reprise :** un fichier de constats de `vf-auditer`, typé et versionné, existe. Recoupe Santé (AUDC-M8, Phase 80).

### Retirer la lecture morte de `lastDesc` (Phase 77, P77-D-12)
**Priorité : basse.** Retirer la lecture morte de `lastDesc` (`ui/00-vibeflow.js:211`), dont le producteur est retiré par la Phase 77 (P77-D-12). **Déclencheur de reprise :** la Phase 80, ou la prochaine phase qui touche `ui/00-vibeflow.js`.

### Mode focus recomposé (AUDC-I27, sous-graphe par ELK ; Phase 80)
**Priorité : non fixée.** En réserve après le worker de mise en page de la Phase 79 ; la Phase 80 livre seulement « cadrer la sélection et ses voisins » (80-12, P80-D-17). **Déclencheur de reprise :** le worker de mise en page de la Phase 79 (79-18) est livré.

## Outillage de planning : deux écarts relevés par les cadrages 76 et 80 — DIFFÉRÉ (2026-11-11)

**Origine :** rapports de cadrage des Phases 76 et 80 (« À verser par la jointure »), 2026-11-11. Aucun sujet existant de ce fichier ne porte l'un ou l'autre (recherche faite à la jointure).

### `check-method-budget.sh` (`rangement_memoires`) juge une mémoire « hors index » par sous-chaîne (Phase 76)
**Priorité : basse.** `check-method-budget.sh` (`rangement_memoires`) juge une mémoire « hors index » par sous-chaîne (`grep -qF` du nom de fichier) : `a.md` est trouvé dans `xa.md`. Le cockpit (Phase 76) juge par égalité exacte. À aligner. **Déclencheur de reprise :** la prochaine modification de `check-method-budget.sh`, ou l'exécution de la Phase 76.

### Gate `check.decision-coverage-plan` : `could-not-parse` sur les identifiants préfixés `P80-D-NN` (Phase 80)
**Priorité : basse.** Le gate rend `could-not-parse` sur les identifiants de décision préfixés `P80-D-NN` ; la couverture de P80-D-01..60 a été vérifiée à la main. Le préfixage est la convention de `CLAUDE.md` (ADR-075) : toute phase qui l'applique peut rencontrer la même réponse. À suivre ici, comme le demande le rapport 80. **Déclencheur de reprise :** la prochaine planification d'une phase dont les décisions sont préfixées, ou toute passe sur ce gate.

## Cockpit : constats du lot 0 bis — DIFFÉRÉ (2026-11-11)

**Origine :** rapport `.planning/missions/2026-11-11-audit-cockpit-lot-0-bis.md`, section « Limites et points ouverts ». Priorité et déclencheur : décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée.

### Isolation du dossier d'état par les suites qui lancent un vrai terminal
**Priorité : basse.** Mots du rapport : « Rien n'oblige par machine une future suite qui lance un vrai terminal à isoler le dossier d'état. » **Déclencheur de reprise :** la prochaine passe sur le terminal ou le lancement.

### Bloc défilant du bandeau : 7 px de dépassement sous son pied collant
**Priorité : basse.** Mots du rapport : « Constat de la recette, sans lien avec M11 : le bloc défilant du bandeau dépasse de 7 px sous son pied collant. » **Déclencheur de reprise :** la prochaine passe sur le terminal ou le lancement.

### « Confirmez-la dans le terminal » gardé environ 1 s après « Lancer »
**Priorité : basse.** Mots du rapport : « Après « Lancer », le panneau de P garde « Confirmez-la dans le terminal » environ 1 s avant « Commande préparée ». » **Déclencheur de reprise :** la prochaine passe sur le terminal ou le lancement.

## Outillage de flotte : cinq écarts relevés à la mission de jointure — DIFFÉRÉ (2026-11-11)

**Priorité : non fixée.** **Origine :** session principale, 2026-11-11, pendant les cadrages simultanés des phases du cockpit.
- **Mode à blanc de E7 :** le gate de sortie n'a pas de mode à blanc pour E7 ; le contrôler sans archiver demande une copie privée du dossier.
- **Balayage par worktree :** le balayage des processus par worktree ne voit pas un serveur de test lancé depuis un dossier temporaire.
- **Registre des agents par compartiment :** E1 compte les agents des missions sœurs, et un worker qui oublie `--phase` reste inscrit au compartiment (neuf entrées le 2026-11-11).
- **Photo de départ unique :** la photo de départ du budget est unique et partagée par des missions simultanées ; E7 reste indéterminé.
- **Plafond de sous-agents simultanés :** le plafond du harnais (20 par défaut, réglable) a fait sauter des contrôles à sept managers lancés ensemble.

**Déclencheur de reprise :** la prochaine passe sur les gates de sortie de mission, le registre des agents ou l'hygiène des workers.

## Sondes instables en CI : deux suites du cockpit — DIFFÉRÉ (2026-11-11)

**Priorité : non fixée.** **Origine :** session principale, 2026-11-11.
- `test-cockpit-lancer-bandeau.sh` : rouge puis vert, relevé pendant le lot 0 de l'audit.
- `test-cockpit-responsive.sh`, cas R15c.2 : rouge sur la PR de release, vert au second passage, même code.

Pas de cause établie. À traiter selon la doctrine des sondes du cockpit : mesurer une fois le rendu posé, attendre la stabilité, ne jamais affaiblir la sonde. **Déclencheur de reprise :** un nouveau rouge d'une de ces deux suites, ou la prochaine passe sur leurs sondes.

**Mise à jour du 2026-11-13 (jointure J1) :** R15c.2 a une cause : défaut de la sonde (`chrome-panneau-etroit.mjs` lisait `textContent` et tapait avant que le focus soit posé), corrigé par `f7214e6b` et `a821e66b` ; il a rougi dans TROIS runs (43197982172, 43300355064, 43384769046). LB.E11 à LB.E14 : toujours sans cause, instable connu (registre J1-19).

**Seconde mise à jour du 2026-11-13 (jointure J1) :** LB.E11 à LB.E14 ont une cause : défaut de la sonde (le serveur factice de `test-cockpit-lancer-bandeau.sh` ne terminait pas l'ancien `GET /flux` à l'arrivée d'un flux neuf, que le serveur réel termine ; les pages quittées restent gelées avec leur flux dans le cache de retour arrière de Chrome, six connexions par hôte, `/entree` fait la queue). Corrigé par `3dc8f31f` (garde LB.D1, mutant M-FLUX-NON-REMPLACE) ; preuve : 4 rouges sur 4 avec un cache de retour arrière à dix pages, 0 rouge sur 3 passages corrigée, suite entière 163 PASS. NON établi : pourquoi le Chrome de la CI retient au moins cinq pages quand celui du poste en retient trois ; le serveur réel n'a pas été mesuré sous Chrome. La règle « relancer une fois » ne vaut plus pour LB.E1x : un rouge de cette suite est à diagnostiquer (registre J1-48).

## Cockpit : journal des attentes par hook (AUDC-I18, P79-Q-04) — RETIRÉ (2026-11-13)

**Priorité : non fixée.** **Origine :** décision déléguée par Samuel (message session principale, 2026-11-11 : « tranche pour chacun de ces points »), prise par la session principale ; versée par la jointure J1. Le journal d'événements par les hooks officiels (AUDC-I18) est retiré : « retirée, sonde verte » (sonde S0 du plan 79-19, tableau relu le 2026-11-11, § 5.3 du registre). SOCL-24 reste au ledger et se clôt par la sonde (« journal non construit »), au segment c de la Phase 79. **Déclencheur de réouverture :** une version de Claude Code qui cesse de publier les états `waiting` / `blocked` dans la vue d'agents officielle ; la sonde se rejoue alors.

## Cockpit : constats versés par la jointure J1 (segments a de 79 et 80) — DIFFÉRÉ (2026-11-13)

**Priorité : non fixée.** **Origine :** jointure J1 du 2026-11-13 ; le détail ligne à ligne, avec état et propriétaire, vit dans `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md`, section « Constats versés par la jointure J1 » (J1-01 à J1-47) et § 5.3. Rien n'y est corrigé par la jointure.
- **Interface (Phase 80, segment b) :** six mineurs du juge à captures (J1-01 à J1-06), couplage du seuil de 701 px (J1-28), `#vf-coin` ignoré par `obstacles()` (J1-29), frappe perdue après « / » (J1-30), liste du tiroir Git sous le plancher de 240 px sans CLI (J1-26), panneau tactile à 1 000 px et plus (J1-27, à trancher).
- **Socle de test (79-b) :** dossiers temporaires et restes de Chrome laissés par les suites, alerte sonore du poste, erreurs de shell silencieuses, causes de rouges non consignées, durées de CI, cas sautés en CI dont O6.17d et O6.19, jamais prouvés (J1-17 à J1-23, J1-33, J1-34).
- **Sécurité basse (lancement de 79-b), par classe :** cinq restes mineurs du lot 0 bis (J1-07 à J1-11).
- **Méthode :** un attendu de mutant ne repose pas sur l'échec d'une commande externe, la CI se lit par ses jobs rouges, un écrivain par arbre pour les preuves, formes de commande qui suspendent un nœud, Docker démarré sans demande, limite du harnais (J1-35 à J1-37, J1-40 à J1-43).
- **Reporté de J1 (consigne d'allègement, demande de Samuel, message session principale, 2026-11-13) :** étape 2 point 8, contrat « attribut neutre posé par le terminal », inversion de CL4.3 et `eviter()` rejoué à l'arrivée de la pastille (J1-49).
- **Ouverts de J1 :** SU6.1 et M-PERSISTANT attendent `VF_COQUILLE` de 79-16 (J1-50) ; angle mort de la porte des chaînes, littéraux français accentués non vus (J1-51) ; ligne `AJOUT` manquante non vue par la suite vendor (J1-52).
- **Design, nœud `docs` de la 71.5 (J1-53) :** jetons d'espacement absents des six fichiers Git et garde `css-jetons.mjs` à étendre ; P71.5-D-10 (gouttière du téléphone, 20 px contre 24) ; pulsation par l'opacité dans `70-vf-live.js` ; valeurs hors grille de `06-blueprint.js`.
- **Mineurs de la revue de J1 (tête `faed809d`, verdict passed, une passe) :** (1) M-ASK-HAUT de `test-cockpit-git-pagination.sh` fige un compte exact de rangées (même famille que l'égalité à 115 px retirée par GP2.3b) : la propriété à la place ; (2) même suite, `$ASK_AVEC` non liée sous `GP_SEULEMENT=MUTANTS` ; (3) la trace « empreinte publiée = celle de la copie » prétend plus que ce qui est vérifié (l'empreinte ne hache pas `assets/ui/*.js`) ; clavier-canevas et coin sans comptage de page ; (4) sous `CL_SCRIPTS`/`CC_SCRIPTS`/`CN_SCRIPTS`, `cockpit_module_copie` copie toujours le dépôt, pas la racine rejouée ; (5) `04-vf-clavier-canevas.js` : `t('{} card', n)` sans pluriel anglais (`t.pl`).

**Déclencheur de reprise :** le cadrage du segment b de la Phase 79 ou de la Phase 80, ou la prochaine passe sur le socle de test du cockpit.

## Verrous par `mkdir` : non exclusifs sous les coreutils uutils jusqu'à 0.10.0 — DIFFÉRÉ (2026-11-13)

**Priorité : à proposer à Samuel par la session principale.** **Origine :** constat de la session principale, 2026-11-12 ; registre J1-31. Sur Ubuntu 25.10 et 26.04 (donc le runner de la CI), `mkdir d` sans `-p` teste l'existence puis crée, et rend 0 si un autre processus a créé `d` entre les deux (lu dans le source de l'outil, versions 0.1.0 à 0.10.0, corrigé en 0.11.0). Preuve en CI : sonde KC2 de `plugin/conductor/scripts/tests/test-check-method-budget.sh`, run 43281286911, première tentative, shard 2 (deux passes d'archivage dans la section critique, l'archive de la gagnante supprimée par le retour arrière de l'autre) ; 2 rouges sur 89 runs mesurés. Sites du même type, hors tests : `plugin/conductor/scripts/check-method-budget.sh`, `plugin/consolidator/scripts/archive.sh` et `reindex.sh`, `plugin/conductor/scripts/check-plugin-update.sh`, `scripts/check-gsd-core-update.sh`. Non concernés : `driver-lock.sh` (départage par `ln -sn`) et `fs.mkdirSync` de Node. **Destination :** lot court à part, compartiment `fiabilite`. **Preuve attendue du correctif :** un faux `mkdir` en tête de PATH qui reproduit la sémantique fautive (rouge avant, vert après). En attendant, un rouge KC2 isolé en CI se relance, en le disant. **Déclencheur de reprise :** la décision de Samuel sur le lot, ou un nouveau rouge KC2.


## Cockpit : mineurs de la revue du point de fusion 1 de la Phase 73 — DIFFÉRÉ (2026-11-13)

**Priorité : non fixée.** **Origine :** revue `vf-reviewer` du point de fusion 1 de la Phase 73 (plans 73-01 à 73-04, PR #243), une passe ; les deux majeurs sont corrigés dans la branche de la phase.
- **`dag` du verrou :** le serveur le projette en objet (`vf-cockpit-vie.mjs`) ; `72-vf-regie-modele.js` n'admet qu'une chaîne et le vide toujours : champ mort, marque « nœuds running » de P73-D-09 non livrée. Trancher : retirer `dag` de la liste blanche, ou admettre l'objet borné.
- **Grammaires du modèle plus étroites que le serveur :** `wsOk` (`[a-z0-9-]`) et `phaseOk` (deux niveaux) contre `[A-Za-z0-9][A-Za-z0-9._-]*` et `1.2.3` : un compartiment à point ou une phase à trois niveaux se vide, deux missions peuvent partager une clé.
- **Échec de lecture des arbres de la route `ailleurs` :** avalé sans trace, et la dernière bonne liste effacée.
- **`fenetreDeStall` :** relit le script de garde (jusqu'à 256 Kio) en synchrone à chaque tour de 5 s ; mémoïser par date de modification.
- **`attendAgents` :** calculé aussi pour les sessions terminées (lecture de transcript inutile).

**Déclencheur de reprise :** la prochaine passe sur la collecte ou le modèle de la régie.

## Cockpit : poids de la traçabilité dans le graphe Projet (P76-Q-03) — OPTION (a) GARDÉE, MESURÉE (2026-11-13)

**Priorité : à juger à la recette.** **Origine :** plan 76-04, mesure de sa suite T9.8 (`76-04-SUMMARY.md`) ; P76-Q-03 gardée en option (a), décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée, prise par la session principale le 2026-11-13. Mesure sur ce dépôt : le graphe Projet passe de 1 538 945 à 2 824 073 octets (+1,29 Mo, trois fois l'estimation de 0,4 Mo du cadrage), dont 820 Ko de références de plans et de critères pour 87 phases (`nodes[].trace`). **Piste (b) :** les définitions des registres et les références de plans lues par la route `GET /api/vf/tracabilite`, à la demande, hors du graphe. **Déclencheur de reprise :** Samuel juge à la recette que l'onglet Projet est lent.

## Cockpit : mineurs de la revue et de l'audit du point de fusion 1 de la Phase 76 — DIFFÉRÉ (2026-11-13)

**Priorité : basse.** **Origine :** revue (`vf-reviewer`) et audit de sécurité (`vf-auditer`) des plans 76-01 à 76-05, une passe chacun, régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Majeur de la revue et constat haut de l'audit corrigés avant la fusion ; restent :
- Revue m1 : les listes `requirements` des PLAN et SUMMARY projetées par la collecte ne passent pas par `servi`, alors que le contrat de 76-04 dit tout texte nettoyé.
- Revue m2 : la recette est cherchée par `-RECETTE-*.md` (premier du tri) dans la traçabilité, par `-RECETTE-HUMAINE.md` dans `avancement.mjs` : un autre nom ferait diverger les deux lectures (P76-D-14).
- Revue m4 : `name` d'une entrée de mémoire lu avec ses guillemets ; un `name: "x"` ne résout pas un lien `[[x]]` (aucun cas dans le dépôt).
- Audit M-1 : la lecture synchrone des fichiers de mémoire n'a ni budget cumulé d'octets ni contrôle d'horloge entre fichiers ; l'échéance de la route ne couvre que git (le coût par fichier est borné depuis le correctif H-1). Un témoin déterministe demande une horloge injectée dans `calculer` (`vf-cockpit-trace.mjs`).
- Audit M-2 : réponse en cache périmée après une écriture en place, non indexée, d'un fichier de mémoire (empreinte par dates de dossiers) ; limite déjà dite au cadrage, à écrire aussi au SUMMARY de 76-05.
- Audit M-3 : les échecs ou troncatures des lectures git de la mémoire (chemins de HEAD, jours, non suivis) ne remontent pas dans `bornes.tronque` : la liste se donne pour complète.
- Audit B-1 à B-3 : noms de fichiers suivis servis sans passer par `servi` ; fragments `cible` et `name` bornés mais issus du texte de la mémoire ; empreinte sans signal git quand `git.sig` est nul.

**Déclencheur de reprise :** la prochaine passe sur la traçabilité du cockpit (76-08 ou la phase suivante qui la lit).

## Cockpit : mineurs des plans 75-01 à 75-06 (Phase 75, activité posée sur le code) — DIFFÉRÉ (2026-11-13)

**Priorité : basse.** **Origine :** exécution des plans 75-01 à 75-06, régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
- 75-01 : `merge-base` absent de la liste fermée des sous-commandes git (`vf-cockpit-git-durci.mjs`) ; P75-D-10 tenu par `rev-list`, à revoir si la liste s'élargit.
- 75-03 : gardes de forme à bords ouverts (bidi U+202E, U+200B, `%2e%2e`, `a\..\x`) : affichage seulement, les chemins ne sont jamais ouverts.
- 75-03 : collisions de plans en texte brut (`./src/a` ≠ `src/a`).
- 75-04 : un bloc de frontmatter de plus de 400 lignes est lu comme absent, sans compteur.
- 75-05 : la partie synchrone de `contexteGardes` (parcours des suites) ne cède pas la main.
- 75-06 : une carte prévue est créée pour tout chemin absent du lab, documents compris (pas de filtre par catégorie).
- 75-06 (revue, m2) : `vf-cockpit-activite-prevues.mjs` crée une carte prévue pour des fichiers non code et des sous-dossiers ignorés ; filtrer par `classify()` et `arch.include`/`ignore`.
- 75-0x (revue, m3) : le nœud `unassigned` vide ajouté par l'annotateur reste dans l'export autonome (`serve.mjs`).
- 75-01 (revue, m4) : `vf-cockpit-activite-branches.mjs`, échéance globale de 15 s pour 66 paires ; plusieurs reprises de 60 s avant convergence sous charge, ce que dit `radar` (`branches-indisponible`).
- 75-04 (revue, m6) : la lecture des listes en bloc peuple `vfTouch`, soit +885 Ko dans `graph.json` et dans l'`index.html` Code ; effet voulu, non mesuré.
- 75-01 (revue, m5) : le tri de la base commune multiple (`baseCommune`, historiques en croix) n'a pas de témoin ; les quatre autres mutants de m5 ont leur témoin (G11).

**Déclencheur de reprise :** la prochaine passe sur l'activité du cockpit (75-07 ou la phase suivante qui la lit).

## Cockpit : mineurs de la revue du point de fusion 2 de la Phase 76 (pages 76-06 et 76-07) — DIFFÉRÉ (2026-11-14)

**Priorité : basse.** **Origine :** revue (`vf-reviewer`) des plans 76-06 et 76-07, une passe, verdict passed, aucun majeur ; régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
- M1 : `74-vf-trace-sections.js` lit les exigences de l'entrée haute sans garde ; une réponse vide, indisponible ou en cours de collecte lève une erreur non rattrapée (console seule, l'entrée reste cachée).
- M2 : les zones rendues de `74-vf-trace.js` ne sont élaguées qu'au rafraîchissement ; des conteneurs détachés restent retenus jusqu'à un événement ou au départ d'onglet (fuite bornée).
- M3 : Échap retrouve la ligne d'origine par un sélecteur sans `CSS.escape` ; un chemin de preuve à guillemet ne rend pas le focus.
- M4 : `ouvrirAgent` (`74-vf-trace-memoire.js`) avale l'échec de lecture ; un clic ne produit rien, ou une liste vide trompeuse pendant la collecte.
- M5 : le marqueur d'injection des sondes ne couvre que le libellé d'exigence et les critères, pas les titres d'ADR, noms de mémoire ni sujets de commit (le code passe tout par `textContent`).
- M6 : trois sondes Chrome à durcir : seuil de 150 ms contre une lecture à 40 ms (à-coup de CI), comparaison de défilement tautologique si le panneau ne défile pas, pause fixe sans témoin d'arrivée de l'événement.
- Non sondé : l'état « collecte en cours » ne se relance que par la clé `planning` de `VF_ETAT` ; si la fin de la première collecte n'émet pas d'événement, la phrase reste jusqu'au prochain changement de panneau. À trancher avec le correctif de la clé `planning` annoncé par la Phase 79.

**Déclencheur de reprise :** la passe du juge de design de fin de Phase 76, ou la prochaine retouche des fichiers `ui/74-vf-trace*.js`.
