# 46-SCOUTING — état des lieux avant cadrage de la Phase 46

> Mission `vf-dev-manager-p46-cadrage`, nœud `scouting-46`, 2026-10-03. Lecture du code seule, rien
> exécuté hors greps, rien tranché. Racine des chemins : le worktree `gouvernance-46` (branche
> `gouvernance/phase-46-cadrage`, empilée sur `origin/gouvernance/phase-45-execution` : la PR #124
> de la 45 n'est pas mergée, 131 commits d'avance sur `origin/main`). `PC` = `plugin/planning-core`.

## 1. Hook central : câblage, nouvel événement, armement, pré-filtre

**Câblage actuel** (`PC/hooks/hooks.json`) :
- `SessionStart` matcher `startup` (l.4-13) : `check-planning-state.sh`, `planning-context.sh`,
  `detect-planning-debt.sh`, `check-gates-alive.sh --hook` (l.11), tous `|| true`, sans `timeout`.
  Second groupe sans matcher : `planning-session-snapshot.sh` (l.14-18).
- `UserPromptSubmit` (l.20-26) : `planning-task-context.sh`. `Stop` (l.27-33) :
  `guard-planning-updated.sh`, exit 2 bloquant, conservé (P45-D-19).
- `PreToolUse` matcher `Write|Edit|NotebookEdit|Bash|Agent|Task` (l.36), une commande inline de
  forme shell (l.40), `timeout: 20` (l.41). Elle contient : `vf_pre && exit 0` (pré-filtre), puis
  `bash planning-hook.sh`, puis le repli shell fail-closed (refus JSON statique, `hookEventName`
  codé en dur `PreToolUse`, fin de l.40).
- Aucun `TaskCompleted`, `SubagentStop` ni `FileChanged` dans aucun `plugin/*/hooks/hooks.json`
  (grep : seuls `modele-cycles.md`, la spec et la fixture `plugin/_internal/tests/fixtures/gsd-core-settings.json:68,82` les nomment).

**Brancher un nouvel événement — ce que le code impose aujourd'hui :**
- L'installeur est générique : `merge-hooks.sh` itère `frag_hooks.items()` (`plugin/_internal/merge-hooks.sh:376`),
  appelé par `merge_module_hooks` (`plugin/_internal/vibeflow-update.sh:1880-1890`). Une nouvelle clé
  d'événement dans `hooks.json` serait fusionnée sans changement d'installeur.
- `planning-hook.sh` ne lit jamais `hook_event_name` (grep vide) ; `main()` (l.2073-2133) suppose un
  appel d'outil (`cible_de` l.196 lit `file_path`/`notebook_path`/`cwd`) ; `sortie_refus` et
  `sortie_contexte` émettent `"hookEventName": "PreToolUse"` en dur (l.799-811). P45-D-15 :
  « un seul script », « la commande enregistrée de P45-D-06 est sa seule porte d'entrée » (45-CONTEXT l.202-205).
- Le canary ne cherche que les groupes `PreToolUse` (`PC/scripts/check-gates-alive.sh:332`), fabrique
  des payloads `hook_event_name = "PreToolUse"` (l.365) et n'accepte comme refus que
  `hookEventName == "PreToolUse"` + `deny` (l.381). `COMMANDE_REFERENCE` (l.152) est une copie de la
  commande de `hooks.json`, comparée par les suites (`test-planning-hook-registered.sh`, `test-planning-prefilter.sh`, etc.).
- `rejeu-gates.sh:972` fabrique aussi des payloads `PreToolUse` seulement.
- `docs/HOOKS-CONTRAT-SORTIE.md` §4 (l.80-86) affirme `assert n==33` entrées de hooks : toute nouvelle
  entrée change ce décompte (planning-core : 8 entrées, l.184-194).

**État d'armement** : constantes dans le code livré, jamais dans le lab (P45-D-03a) :
`ARMEMENT_G6/G5/G1/G7/ROLE = "armed"`, `G2_MODE = "avertit"`, `ORDRE_ETAPES = (("G6","G5"),("G1",),("G7",),("ROLE",))`
(`PC/scripts/planning-hook.sh:103-110`). `armement_valide` (l.475-491) refuse tout si une étape est armée
avant la précédente. Passage `observe` → `armed` = commit qui change la constante, après canary vert
+ 0 faux refus / 0 faux accept sur banc puis rejeu réel (P45-D-03, P45-D-03b, 45-CONTEXT l.84-105).
Le canary relit ces constantes par regex `^ARMEMENT_<gate> = "…"` pour les gates du tuple
`GATES = ("G6","G5","G1","G7","ROLE")` (`check-gates-alive.sh:180, 465-480`). R-REFERENCE compare la
table de `modele-cycles.md` l.863-870 au code (`test-planning-gates.sh:4592`).

**Pré-filtre hors adhésion** : `vf_pre` en tête de la commande `PreToolUse` (`hooks.json:40`, même texte
dans `COMMANDE_REFERENCE`). Décide « court-circuit » (exit 0 sans script, `mktemp` ni `python3`)
seulement si TOUTES les valeurs `file_path`/`notebook_path`/`cwd`, `$PWD` et le cwd physique sont
absolues, propres, ≤ 1024 caractères, ≤ 64 composants, et qu'aucun ancêtre (lexical et physique) n'a
de `.planning/config.json` portant `cycles-v1` (casse ignorée), illisible ou non régulier ; sinon chemin
complet (`modele-cycles.md:767-794`). Bornes F-P3 : config > 64 Kio (`find -L … -size +128`) → DEFER,
budget 64 lectures de config par exécution (l.787).
- Coût mesuré (quick 261002-brz, SUMMARY l.21-24, médianes /bin/sh, 40 rejeux) : dans ce dépôt Write
  45,0 → 12,4 ms, Bash 45,0 → 12,1, Agent 45,3 → 12,1 ; lab adhérent synthétique 45,2 → 49,4 ms (+4 ms).
- Après F-P3/F-P4 (quick 261003-1le, SUMMARY l.21-26) : Write 43,4 → 15,1 ms, Bash 43,2 → 14,8, Agent
  43,2 → 14,8 ; le `find` coûte ~3 ms (deux configs sur la chaîne).
- Limite F-P5 (`modele-cycles.md:787`) : sans `find` dans le PATH du hook, la borne de taille se perd en
  silence ; non exploitable sans contrôle du PATH ; correctif possible non fait (`-size -129`).

## 2. `poser-verdict.sh` et le format de `VERDICT.md`

- Gabarit (`PC/references/templates/cycles/VERDICT.template.md:1-9`) : `juge`, `hash`, `tentative: 1`,
  `score: ""`, `constats:` liste de `{critere, resultat}` ; prose l.19-21 : hash et tentative « lus et
  restitués, jamais vérifiés » en 44, vérification en 46.
- Écrit par la commande (`PC/scripts/poser-verdict.sh:357-368`) : `juge: "…"`, `hash: "<sha256>"`,
  `tentative: <n>`, `score: "…"`, `constats` (`resultat` ∈ `passé`/`échec`, l.64, l.408-411).
- **Ce qui est haché (A3 = a3-plan)** : sha256 des octets du `PLAN.md` de l'unité, calculé par la
  commande via `hashlib`, sous verrou `flock` (l.17-20, l.421-425). Pas le livrable : l'en-tête le dit
  (« ne prouve pas que le livrable jugé est celui qui a été produit », l.18-20) ; option écartée
  `a3-livrables` (empreinte composée des `ecrit:`) décrite dans `45-04-PLAN.md:195-198`.
- **Tentative : déjà présente et vérifiée** : `--tentative` obligatoire, 1 à la création, ancienne + 1
  pour remplacer, sinon code 64, fichier inchangé (l.349-355, l.427-437). Un `VERDICT.md` existant sans
  tentative lisible est refusé (l.433-435).
- Autres contrôles : unité de forme modèle (l.317-329, l.420), `PLAN.md` régulier obligatoire (l.421-423),
  caractères de contrôle refusés (l.305-314), relecture par le parseur identique (l.371-377), écriture
  atomique sans traverser de lien (l.380-393). Codes 0/1/2/64 (l.28-29).
- **F8 = f8-agnostique** (l.10-15 ; `modele-cycles.md:1006-1009`) : la commande ne sait pas qui la lance,
  `--juge` est déclaratif ; le juge la lance s'il a `Bash` (seul `vf-design-judge`), sinon le manager
  la lance sur son rapport (quality-gate-client, content-clarity-judge, growth-quality-judge n'ont pas Bash).
- **G5** refuse toute écriture par outil (`Write`/`Edit`/`NotebookEdit`) d'un `VERDICT.md` (casse ignorée)
  sous `.planning/` d'un lab adhérent, liens durs compris, parcours borné à 20 000 fichiers
  (`modele-cycles.md:911-917` ; `evaluer_g5`, `planning-hook.sh:1047`). La commande, lancée par `Bash`,
  n'est pas vue par G5.
- **Nulle part le hash n'est comparé** : le recalcul le lit dans `_meta_unite` et le restitue en
  `hash_juge` (`PC/scripts/recalc-planning.sh:1020-1033`), sans contrôle ; aucun gate ne le relit.

## 3. Modèle, clôture, entrées de G3/G4

- Huit états + trois dérogations (`modele-cycles.md:426-441` ; `ETATS_TOUS`, `TERMINAUX`,
  `recalc-planning.sh:102-107`).
- **Marqueur de clôture** = `CLOTURE.md` à côté de `PLAN.md` (`cloture_par`, `cloture_le`), seule sa
  présence compte ; `PLAN.md` jamais modifié pour clore (hash stable, P44-D-03) (`modele-cycles.md:364-378`).
- **Livrables déclarés** : champ `ecrit:` (scalaire ou liste) du frontmatter de `PLAN.md`, chemin relatif
  à la racine du lab, forme contrôlée (`modele-cycles.md:357-362` ; R2, `recalc-planning.sh:1086-1092`).
  R4 (l.1100-1103) : `os.path.lexists` par entrée → `indéterminé` (`livrable-absent:<entrée>`).
  **Ni la vacuité ni le type** (fichier/dossier vide) ne sont testés ; la spec dit « absent **ou vide** »
  pour G3 (spec moteur l.338).
- **Constats** : `constats` = liste non vide de `{critere, resultat}` ; R6 `verdict-invalide` si absent,
  vide ou résultat hors `passé`/`échec` ; R7 un `échec` → `à corriger` (ou contradiction si SUMMARY) ;
  R8 tous `passé` + SUMMARY → `close` (`recalc-planning.sh:1109-1128`).
- **P44-D-08 / « à clore »** : R8 sans SUMMARY rend `indéterminé` (`verdict-passe-sans-SUMMARY.md`),
  « état de transition normal », le moteur « avoue plutôt que de deviner » (`modele-cycles.md:491-497`) ;
  libellé « verdict passé, SUMMARY absent » (`recalc-planning.sh:119`). ROADMAP l.222-225 : « à envisager
  au cadrage » un état « à clore ». Points de contact d'un nouvel état : `ETATS_TOUS` (l.104-107), R8
  (l.1123-1128), `LIBELLES` (l.119), agrégation (non terminal par défaut, l.102 et l.1279-1283),
  tables `modele-cycles.md` l.426-437, 484-485, 508-536, 648-658, gabarit `VERDICT.template.md:16-17`,
  la spec §3.1 (« huit états »), suites `test-recalc-planning.sh` et `rejeu-gates.sh` (classification
  par `recalc-planning.sh --read-only`, `modele-cycles.md:1045-1047`).
- **Seuil de juge dans `config.json`** : absent. Ni `config.template.json` (4 clés), ni le hook, ni le
  recalcul ne lisent de seuil (grep `seuil` vide hors prose). La spec §10 l.643-644 le prévoit (« le
  modifier est un refus de classe G5 sauf dérogation ») ; G6 ne protège dans `config.json` que
  `planning_version` (`modele-cycles.md:903-906`). Les seuils vivent dans les prompts des juges
  (80/100 : `content-clarity-judge.md:39`, `quality-gate-client.md:41`, `growth-quality-judge.md:39` ;
  70 par défaut, fourni par le manager : `vf-design-judge.md:70`) ; le `score` est non bloquant (D-02 amendée).

## 4. Canary existant et notion de « sortie piégée »

- **Ce que prouve `check-gates-alive.sh`** (en-tête l.1-74) : au `SessionStart` d'un lab adhérent, il
  retrouve la commande enregistrée, exige qu'elle soit égale à `COMMANDE_REFERENCE`, la rejoue sur un lab
  synthétique `mktemp` et signale (jamais ne bloque) : hook non enregistré / non reconnu, mode dégradé,
  armement illisible ou gate armé sans cas, cas en échec. Codes 0 signal, 3 sain, 4 indéterminé, 64 usage.
  16 cas `CANARIS` (l.213-238) : 8 `DEGRADE` (script absent, python absent × Write/Agent/Task/Bash), G6×2,
  G5×2, G1, G7, ROLE×3. Couverture minimale à 6 éléments (l.184). L'attendu est dérivé de la table
  d'armement (l.530). Deux agents synthétiques `canary-juge`, `canary-worker` (l.202-210).
- **Ce qu'il ne prouve pas** : aucun comportement d'agent ; il ne joue que des payloads d'outil contre
  le hook (bash + python, aucun appel de modèle). Il n'existe aucun mécanisme qui dispatche un juge.
- **« Sortie piégée » dans le dépôt** : le terme n'apparaît que dans les specs (init C-16 l.105-106,
  famille 2 l.197, §10 l.497-501) et la ROADMAP l.218. Aucun fichier, gabarit ni script ne la porte.
  La fabrication est rattachée à l'initialisation (Phase 50, ROADMAP l.22 et l.293-296), postérieure à la 46.
- **Notions voisines existantes** : « exemples-étalon » et test de discrimination « rejette un mauvais
  output connu ET valide un bon output connu » (`plugin/audit-architecture/references/rubric-design.md:58-62, 79-84` ;
  `audit-layer-primitive.md:48` ; `enforcement-spectrum.md:36-38, 69`), convention
  `references/exemples-etalon.md` du skill auditeur — aucun fichier de ce nom n'existe dans `plugin/`.
- **Les quatre juges livrés** : rubriques /100 inline dans le prompt, critères éliminatoires,
  `disallowedTools: Write, Edit`, `vf-internal: true` (l.4-10 de chacun) ; aucun étalon ni contre-exemple
  joint. `canary-juge` du canary n'est qu'une définition pour le gate ROLE (« jamais exécuté », l.206).

## 5. Limites de `modele-cycles.md` qui touchent la 46

1. (g) Bash reste ouvert en mode dégradé : un verdict, une clôture ou un livrable s'écrivent par Bash (l.811).
2. (i) `$CLAUDE_PROJECT_DIR` choisit quelle copie du hook s'exécute ; seul le canary le rend visible (l.813).
3. (l) L'allowlist d'un worker vit dans une définition d'agent que G6 ne protège pas (l.816).
4. (n) Un `sed` par Bash qui retire l'adhésion désarme tous les gates (l.818).
5. (q) Sémantique du harnais non mesurée pour un dispatch sans `subagent_type` ou `fork` (l.821).
6. (r) Journal d'observation sans borne ni rotation (l.822) : tout nouveau gate en `observe` y écrit.
7. (s) Coût : échéance interne de 8 s du cœur, déni de service possible sous charge (l.823).
8. (y) Réglages `.claude/settings*.json` non protégés : un `Write` qui retire un hook désarme (l.829).
9. (z) Faux refus sous forte charge (SIGALRM, code 73) (l.830).
10. (ac) Racine d'un dispatch `Agent`/`Task` dérivée de clés non établies du harnais (l.833).
11. (ae) Seuls les outils du matcher sont vus ; `MultiEdit`, outils MCP hors gates (l.835) — c'est le trou que D1 (`FileChanged`) vise.
12. (ah) Adhésion lue différemment par le cœur et la couche shell (l.838).
13. Hors limites lettrées : `--juge` déclaratif, hash = plan et non livrable (l.1006-1009) ;
    « G2′, G3, G4, G4′ et D1 … Phases 46 et 47 ; vérification du hash à la clôture : Phase 46 » (l.1063-1064) ;
    `hash`/`tentative` « lus et restitués, jamais vérifiés » (l.393-394) ; limite R4/symlink intermédiaire (l.367-372).

## 6. Ce que la 44 et la 45 ont renvoyé à la 46

- 45-CONTEXT l.38-39 et l.467 : G2′, G3, G4, G4′, D1 (`TaskCompleted`, `SubagentStop`, `FileChanged`) →
  46 et 47 ; vérification du hash de `VERDICT.md` à la clôture → 46.
- 45-CONTEXT l.164-169 (P45-D-07) : la commande pose hash + tentative ; « la vérification du hash à la
  clôture reste en 46 ».
- 45-04-PLAN l.170-198 et 45-04-SUMMARY l.166 : A3 retenu (hash du plan) en sachant que « la Phase 46
  vérifiera ce hash à la clôture » ; l'option livrables « la 46 doit reproduire exactement la composition ».
  45-RESEARCH l.674 : A3 « à confirmer (Phase 46 vérifie le hash contre l'artefact effectivement produit) ».
- 44-CONTEXT l.76-80 (D-03 : hash de `PLAN.md` stable « ce que consommeront les verdicts hachés de la
  Phase 46 ») et l.131-134 (D-09 : vérification de `hash` et `tentative` → 46).
- ROADMAP l.222-225 : état « à clore » à envisager (origine 44, décision (a), head sous délégation
  technique de Willy, session principale, 2026-09-28). ROADMAP l.236 : G2′ (Phase 47) se branche sur le
  même `TaskCompleted` que G3/G4.
- Aucune occurrence de « à clore » hors ROADMAP (grep `.planning/workstreams/gouvernance`, `PC`, specs).

## 7. Suites à étendre et gates de dépôt

Suites (comptes et durées tels que relevés, non rejoués ici ; sources : `45-VERIFICATION.md:161-166`,
quick 261002-brz SUMMARY l.25-27, quick 261003-1le SUMMARY l.19-20) :

| Suite | Cas | Durée connue |
|---|---|---|
| `PC/scripts/tests/test-planning-gates.sh` (4 960 l.) | 461 OK | 3 min 43 (à 446 cas) |
| `PC/scripts/tests/test-planning-hook-registered.sh` (1 952 l.) | 90 OK | 22 s (à 50 cas) |
| `PC/scripts/tests/test-recalc-planning.sh` (4 530 l.) | 358 OK | 40 s |
| `PC/scripts/tests/test-rejeu-gates.sh` (2 251 l.) | 91 OK | 1 min 58 |
| `PC/scripts/tests/test-planning-prefilter.sh` (1 284 l.) | 19 OK + 23 mutants | > 600 s machine chargée (scindée) |
| `plugin/_internal/tests/test-planning-hook-installed.sh` (1 000 l.) | 23 OK | 10 s |
| `scripts/tests/test-role-hook-vs-check-agents.sh` (238 l.) | 6 OK | 11 s |

- CI : toute suite `*/tests/test-*.sh` est découverte automatiquement (`.github/workflows/ci.yml:218`).
- **Gate-Touche (G-2)** : la surface de `scripts/check-gate-touche.sh` est fermée à
  `plugin/conductor/scripts/check-*.sh`, `scripts/check-*.sh`, leurs suites, `.github/workflows/ci.yml`,
  `scripts/hooks/` (l.25-30, classifieur l.204-215) : `PC/scripts/*` et `PC/hooks/hooks.json` n'y sont pas.
  La 45 s'est imposé un marqueur sur tout commit touchant un hook ou sa suite (45-CONTEXT l.419, l.442),
  contrôlé par l'artefact de phase `45-CONTROLE-MARQUEUR.sh`.
- **Baseline du budget d'instructions** (`.planning/instruction-budget-baselines.tsv`, CODEOWNERS l.26) :
  ne couvre que les agents (31 fichiers) ; les quatre juges y sont (91/10, 82/7, 85/9, 84/8). Touchée
  seulement si la 46 modifie un prompt d'agent ; une hausse exige une citation d'arbitrage (G-1).
- **check-agents.sh** (ADR-044) et densité ADR-029 : concernés si un agent est créé ou modifié (juges :
  86 à 96 lignes aujourd'hui). `test-role-hook-vs-check-agents.sh` recoupe la dérivation de rôle.
- `docs/HOOKS-CONTRAT-SORTIE.md` §4 (`assert n==33`) et `scripts/tests/test-hook-exit-parc.sh` (inventaire
  déclaré, l.23-63) suivent le parc de hooks.

## 8. Versions

- `PC/VERSION` : `v2.9.0` (CHANGELOG `[v2.9.0] — 2026-10-01`, Phase 45 ; `module.json` l.3 identique).
- `plugin/conductor/VERSION` : `v1.46.0`.
- `VERSION` racine : `v2.68.0` (= `plugin/.claude-plugin/plugin.json:4`, `.claude-plugin/marketplace.json:11` ; tag `v2.68.0` présent).

## Zones grises repérées (non tranchées par les sources)

1. **Quel événement porte G3/G4 dans un lab métier.** La spec les met sur `TaskCompleted` (l.337-339,
   351-354) ; le scouting de la 45 a relevé que `TaskCompleted` « concerne `TaskUpdate` et les équipes
   d'agents, pas le dispatch `Agent` » (`45-SCOUTING.md:45`). Or la clôture du modèle est l'écriture de
   `CLOTURE.md` (puis `SUMMARY.md`), donc un `Write` vu par `PreToolUse`. Les sources ne disent pas si
   G3/G4 se branchent sur `TaskCompleted`, sur l'écriture de `CLOTURE.md`/`SUMMARY.md`, ou sur les deux.
2. **Contrat de sortie des nouveaux événements.** P45-D-08 et spec §5.1 : refus par
   `permissionDecision: deny`, jamais exit 2 ; mais la spec l.352-354 dit « `exit 2` empêche la tâche
   d'être marquée close », `TaskCompleted` « refuse par exit 2 » et `SubagentStop` par `decision:"block"`
   ou exit 2 (`45-SCOUTING.md:44-45`). `permissionDecision` est propre à `PreToolUse`.
3. **G4′ et les juges sans Bash.** « Rapport sans sortie de commande brute refusé » : trois juges sur
   quatre n'ont pas `Bash` (§2, F8) et ne peuvent pas produire de sortie de commande. Les sources ne
   disent pas à qui G4′ s'applique (tous sous-agents, workers seulement, juges exclus ?) ni ce qu'est
   une « sortie brute » vérifiable.
4. **Où lire le rapport pour G4′.** `45-SCOUTING.md:44` : depuis v2.1.271 le rapport `SubagentHandback`
   est dans `tool_input.message` d'un hook matché sur cet outil, pas dans `last_assistant_message` de
   `SubagentStop`. `SubagentStop` ou `PreToolUse(SubagentHandback)` : non tranché ; le second élargit le
   matcher central (coût du pré-filtre, payload sans `file_path`).
5. **Ce que « vérifier le hash » veut dire avec A3 = plan.** Le hash couvre `PLAN.md`, pas le livrable
   (`poser-verdict.sh:17-20`). Le goal dit « hash de l'artefact jugé » ; vérifier à la clôture que le
   `PLAN.md` n'a pas bougé ne prouve rien sur le livrable. Garder A3, passer à une empreinte composée
   des `ecrit:` (format sur disque « costly », `45-04-PLAN.md:204`), ou les deux : ouvert. Où vit la
   vérification (recalc → `indéterminé` ? gate ? les deux ?) : ouvert.
6. **Tentative : déjà livrée.** Le compteur existe et est contrôlé à la pose (§2). Ce que la 46 y ajoute
   (plafond anti-boucle ? lecture à la clôture ?) n'est écrit nulle part ; aucune borne de tentatives
   n'est fixée dans les sources.
7. **« Absent ou vide »** : R4 ne teste que l'existence (`lexists`). Définition de « vide » pour un
   livrable dossier, un fichier de 0 octet, un lien : non tranchée.
8. **Canary de juge et B-01.** C-16 : « le canary du moteur la joue au premier cycle » ; B-01 écarte la
   validation par exécution « le canary du moteur couvre ce besoin ». Le canary actuel ne fait aucun
   appel de modèle et tourne au `SessionStart` en bash. Qui dispatche le juge, quand (« premier cycle » :
   premier `SessionStart` adhérent ? première phase ?), à quel coût, avec quel signal : non spécifié.
   Et la sortie piégée est fabriquée par la Phase 50, après la 46 : format, emplacement, et
   comportement de la 46 en son absence (labs existants, juges livrés sans exemple raté) non définis.
9. **Seuil de juge dans `config.json`** (spec §10) : non implémenté, non renvoyé explicitement à la 46,
   et en tension avec les seuils écrits dans les prompts des juges et le `score` non bloquant.
10. **`FileChanged` (D1)** : watch-list de noms littéraux, ne bloque rien, tourne après l'écriture
    (`45-SCOUTING.md:46`). Quels noms surveiller, où « tracer » (journal d'observation sans rotation,
    limite (r) ? `cloture.log` ?), et coût hors adhésion : l'entrée est posée dans les réglages pour
    toute session ; aucun pré-filtre n'existe pour un événement sans `tool_input`. Aucune mesure de coût
    de ces trois événements n'existe dans le dépôt.
11. **« Un seul script » (P45-D-15) vs trois nouveaux événements** : mode par événement dans
    `planning-hook.sh` ou scripts séparés ; repli fail-closed shell (spécifique à `PreToolUse`) pour
    les autres événements ; extension de `ORDRE_ETAPES`, du canary (`GATES`, `CANARIS`, couverture
    minimale) et de R-REFERENCE : non tranchés. Fail-closed déclaré pour G3/G4 (spec §5.1 l.369-370),
    rien pour G4′ et D1.
12. **État « à clore »** : ajouter un neuvième état touche la spec (« huit états »), le recalcul, les
    libellés, l'agrégation (terminal ou non) et `rejeu-gates.sh` ; laisser `indéterminé` garde P44-D-08.
13. **Release** : `PC` est en `v2.9.0` sur une branche non mergée ; garde-fou de `CLAUDE.local.md` :
    aucune release gouvernance avant la clôture de `fiabilite-v1.0`. Numéro de la 46 non fixé.
