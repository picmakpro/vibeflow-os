---
gsd_state_version: 1.0
workstream: gouvernance
milestone: gouvernance-labs-v1.0
milestone_name: « le planning métier tenu par une machine »
current_phase: 43
current_phase_name: Fabrique — gate des skills par nature et alignement de skill-creator
status: verifying
created: 2026-09-23
last_updated: "2026-09-26T20:30:00.000Z"
last_activity: 2026-09-26
last_activity_desc: >-
  Phase 43 exécutée et vérifiée (mission vf-dev-manager 2026-09-26, exécution) : 7 plans en
  4 vagues, 43-VERIFICATION.md passed 10/10, revue du diff complet PASS après deux mandats de
  correction ciblée (trois passes de revue), audit SECURED. Deux correctifs hors plan (témoin des merges restreint à
  l'amont ; compteur des README racine 89 → 90) et le faux vert de --verify laissé au BACKLOG
  (option B) : décision du head sous délégation technique de Willy, session principale,
  2026-09-26. STATE tenu à la main.
stopped_at: "Phase 43 exécutée et vérifiée ; PR #111 en brouillon, empilée sur gouvernance/phase-42-fabrique, en attente du merge de la PR #108 puis de la revue code owner de Samuel"
progress:
  total_phases: 9
  completed_phases: 0
  total_plans: 13
  completed_plans: 13
  percent: 100
---

# Project State

## Current Position

Phase: 43 (Fabrique — gate des skills par nature et alignement de skill-creator) — EXÉCUTÉE ET VÉRIFIÉE (43-VERIFICATION.md passed 10/10), PR #111 en brouillon. Phase 42 : exécutée et vérifiée, PR #108 en attente de la revue code owner de Samuel.
**Last Activity:** 2026-09-26
**Last Activity Description:** Exécution de la Phase 43 (mission `.planning/missions/2026-09-26-gouvernance-43-exec.md`). Base de phase figée sur `22179fa` ; vagues 1 à 4 intégrées ; FABR-06..10 cochées au ledger ; revue PASS après deux mandats de correction de 43-04 (`bb23de7`, `394c795`), audit SECURED, audit documentaire vert. Planification : `.planning/missions/2026-09-25-gouvernance-43-plan.md`.

## Progress

**Phases Complete:** 0 (Phases 42 et 43 exécutées et vérifiées, non clôturées : PR #108 et #111 ouvertes)
**Current Plan:** aucun — 7/7 plans exécutés sur la Phase 43 ; 6/6 sur la Phase 42

## Session Continuity

**Stopped At:** Phase 43 exécutée et vérifiée ; PR #111 en brouillon, empilée sur `gouvernance/phase-42-fabrique`. Prochain geste : merge de la PR #108, puis rebascule de la #111 vers `main` (intégration amont par rebase uniquement, base de phase re-consignée selon la procédure de 43-01), puis revue code owner de Samuel.
**Resume File:** `.planning/missions/2026-09-26-gouvernance-43-exec.md`

## Note pour Willy (2026-09-23, partition D-02)

Ce compartiment reçoit le jalon `gouvernance-labs-v1.0` (Phases 42-50) — voir
`.planning/workstreams/gouvernance/ROADMAP.md` et `REQUIREMENTS.md` (`FABR-01..05`). Le contenu déjà
planifié de la Phase 42 (6 plans + `42-CONTEXT.md`/`42-RESEARCH.md`/`42-PATTERNS.md`/`42-VALIDATION.md`)
a été déplacé tel quel depuis la racine, rien réécrit. Détail complet de la partition :
`.planning/missions/2026-09-23-partition-planning-d02.md`.

**Ce qui change concrètement** : `.planning/active-workstream` (racine, partagé) pointe par défaut
sur `fiabilite` — toute commande `gsd-tools`/`gsd_run` qui ne précise rien résout `fiabilite`, PAS
`gouvernance`. Pour travailler ici, passe `--ws gouvernance` explicitement à chaque appel, ou exporte
`GSD_WORKSTREAM=gouvernance` dans ton worktree pour la durée de la mission (jamais les deux à la fois
sans vérifier lequel prime — `--ws` court-circuite toujours l'environnement).

**Amendé le 2026-09-24** — exécution en parallèle autorisée (autorisation Samuel du 2026-09-23 rapportée par Willy, session principale, 2026-09-24 (canal non précisé)) ; aucune release avant la clôture de `fiabilite-v1.0` (voir l'en-tête du jalon dans `ROADMAP.md`). Rappel d'origine :

**Rappel non modifié par cette partition** : aucune exécution du jalon avant la clôture de
`fiabilite-v1.0` (Samuel, WhatsApp, 2026-09-23) — être inscrite ici ne vaut pas feu vert.

**Ce fichier rend `rc=2` (« milestone introuvable ») si tu rejoues `check-state-integrity.sh`
dessus tel quel.** C'est attendu, pas une corruption : le frontmatter d'un compartiment tout juste
créé par le moteur n'a pas encore de champ `milestone:` ni de ligne `^Phase:` — c'est la
dégradation honnête d'un compartiment neuf. Ça se résorbe tout seul au premier geste GSD réel ici
(`gsd-new-milestone --ws gouvernance`, ou l'équivalent qui pose ces champs).

**La CI de ce dépôt ne vérifie QUE le compartiment `fiabilite`** (`ci.yml:353`, cible en dur
`.planning/workstreams/fiabilite/STATE.md` — choisie exprès pour qu'un `export GSD_WORKSTREAM` ne
puisse pas détourner le gate vers un autre fichier). Elle ne se prononcera donc JAMAIS sur l'état de
`gouvernance` — ni pour dire que c'est cassé, ni pour dire que c'est bon. Si tu veux savoir où en
est ton compartiment, rejoue le gate toi-même avec `--file .planning/workstreams/gouvernance/STATE.md`
explicitement ; n'attends rien de la CI sur ce point.

### Decisions

- **2026-09-26 — mission d'exécution de la Phase 43 (vf-dev-manager)** : trois décisions du
  head sous délégation technique de Willy, session principale, 2026-09-26. (1) Le témoin
  `MERGES-DANS-LA-PLAGE` (43-01, 43-06) ne compte plus que les merges dont un parent n'a pas B43
  pour ancêtre : les merges internes de la vague 2 sont admis, un merge de l'amont rougit toujours
  (`f24fb79`). (2) Le compteur des README racine passe de 89 à 90 suites hors plan (`b2a1f0c`,
  attributions corrigées en `31b4163`). (3) Le faux vert possible de `inject-mcp-tools.sh --verify`
  sur un dossier mixte n'est pas corrigé dans cette phase : il est porté au BACKLOG (`a2201c1`) et
  en tête des points à relire de la PR #111.

- **2026-09-26 — mission de planification de la Phase 43 (vf-dev-manager)** : Q1 = ratchet sur le
  socle minimal du bootstrap (ligne de baseline `@bootstrap:socle` à la mesure du jour, ≈ 2 499
  tokens ; le plafond ADR-029 de 2 000 reste un objectif, inscrit au BACKLOG). Q-PORTEE = la dérive
  procédurale est cherchée dans tout le corps hors blocs de code ; elle est signalée à partir de
  deux marqueurs distincts en prose, ou d'un seul dans un titre (10/21 SKILL.md au 2026-09-26),
  toujours en avertissement. Décision déléguée par Willy au head (/vf-decide), AskUserQuestion
  session principale, 2026-09-26. Le goal de la Phase 43 est amendé dans la ROADMAP selon D-Q3
  (Willy, AskUserQuestion, session principale, 2026-09-24 : deux déclarations MCP conservées).

- **2026-09-24 — mission Phase 42 (vf-dev-manager)** : recouvrement avec la PR #100 (`fiabilite`, Samuel)
  mesuré avant le premier dispatch. Il est **numérique, pas sémantique** : les deux PR bumpent `conductor`
  (#100 : v1.40.0 → v1.41.0 ; 42-06 : mineure) et touchent `ci.yml` à des étapes différentes (#100 :
  intégrité du STATE ; 42 : étapes `check-agents`). Traité par le garde-fou de l'en-tête du jalon, sans
  arrêt de mission : la PR de la 42 se rebase et renumérote `conductor` après le merge de la #100. Un
  recouvrement de logique (même script, même étape) aurait été une condition d'arrêt.

- **2026-09-24 — vague 1 (vf-coder, nœud exec-42-w1)** : `gsd-execute-phase 42 --ws gouvernance
  --wave 1` a résolu l'isolation en `harness-worktree` puis dégradé automatiquement à `none`
  (`worktree.base-check` : HEAD 13fcd278 divergent d'`origin/HEAD` 3dc082ec — règle #683 documentée
  du moteur, pas une décision de ma part). Les trois plans de la vague (fichiers disjoints) ont donc
  tourné **séquentiellement** sur cette worktree au lieu de trois worktrees parallèles — même
  résultat, ordre 42-01 → 42-02 → 42-03. Le sentinel `dispatch-isolation` doit être re-persisté
  (`record-dispatch-isolation --isolation none`) avant chaque dispatch : `dispatch-isolation --raw`
  sans `--force-isolation` se re-résout à chaud depuis la capacité de l'hôte et efface le
  précédent, un garde `PreToolUse` bloquant sinon le dispatch suivant (observé entre 42-01 et
  42-02, corrigé avant 42-03).

- **2026-09-25 — vague 2 (vf-coder, nœud exec-42-w2)** : même dégradation d'isolation que la
  vague 1 (`worktree.base-check` : HEAD e3ba8f9 divergent d'`origin/HEAD` — attendu, sentinel
  re-persisté en `none` avant le dispatch de l'exécuteur de 42-04). La vague 1 avait touché
  `check-agents.sh` et `test-check-agents.sh` (commits ba312e0, bb36787, a9e98ac) sans trailer
  `Gate-Touche` — corrigé rétroactivement dans le premier commit de cette vague qui touche
  `check-agents.sh` (8c507e7), portée branche de la garde G-2 : `check-gate-touche.sh` confirme
  `marqueurs: lus=8 conformes=8`, `DECLARE`, `rc=0`. `requirements.mark-complete` non appelé par
  l'exécuteur (mandat override) : FABR-02 coché à la main ci-dessous dans `REQUIREMENTS.md`.

- **2026-09-25 — reprise de mission (vf-dev-manager)** : la mission s'est interrompue sur une erreur
  API après le nœud `exec-42-w3a` ; verrou de driver repris par `takeover` (même owner, génération
  DRIVER.lock.gen.1790330288.41231), un seul orphelin (le relecteur, déjà rendu) fermé. **42-06
  (vague 4) est tenue derrière l'arbitrage D-08** : son frontmatter dépend de 42-05, qui n'est pas
  complet ; elle modifie le même `check-agents.sh` que la Tâche 3 de 42-05 et fige la mineure et le
  CHANGELOG de `conductor`, qui doivent décrire l'état d'I5/I6 après arbitrage. L'exécuter avant
  rendrait provisoire la Tâche 3 de 42-05.
- **2026-09-25 — seconde sonde D-19 (`sonde-d19b`, règles à `paths:`)** : décidée par Willy
  (AskUserQuestion, session principale, 2026-09-24). Bloquée une première fois : `claude -p` ne
  s'authentifie pas sous HOME temporaire. Willy a choisi un jeton dédié (AskUserQuestion, session
  principale, 2026-09-24), déposé hors dépôt ; la sonde tourne dès qu'il existe. Limite à
  consigner avec elle : la première sonde (`sonde-d19`) tournait avec le HOME réel.

- **2026-09-25 — fix-42-condition-2 (vf-coder), arbitrage du budget d'instructions, option (b)** :
  les commits `6ca1de8`/`f257306` avaient remplacé « interdits » par « garde-fous » dans les
  digests de `vf-growth-manager`/`vf-design-manager` pour repasser sous la baseline de
  `check-instruction-budget.sh` — un contournement du marqueur textuel D-01. Rejeté : « arbitrage
  Willy, AskUserQuestion session principale, 2026-09-25 » — « interdits » rétabli dans les trois
  fichiers concernés (`vf-growth-manager.md`, `vf-design-manager.md`, `vf-design-judge.md`), et
  `.planning/instruction-budget-baselines.tsv` monté en conséquence sur la même citation
  (24→25, 29→30, 8→9). Détail : `42-05-SUMMARY.md` § Correction — arbitrage du budget
  d'instructions.

### Dette / à rafraîchir

- **Manifeste daté de `check-agents` périmé le 2026-10-24** (`verifie_le` 2026-09-23 sur les six
  listes, `valide_jours` 30 : frais jusqu'au 2026-10-23 inclus). La CI passe
  `--manifest-freshness=strict` : sans rafraîchissement des six listes (sources officielles relues,
  `verifie_le` redaté), les étapes `check-agents` de la CI rendront INDÉTERMINÉ (rc=3, étape rouge)
  à partir de cette date. Relevé par la revue `revue-42-partiel` (2026-09-25).

- **A2 — collision de nom entre scripts de modules non détectée à l'installation** :
  `plugin/_internal/vibeflow-update.sh` pose les scripts (et fichiers `*.json`) de TOUS les
  modules installés à plat dans un seul `.claude/scripts/` du lab cible — un même nom de fichier
  `.sh` porté par deux modules différents écrase silencieusement l'un par l'autre, sans aucun
  diagnostic. Dette **antérieure** à la Phase 42 (l'installeur est hors périmètre du nœud
  `fix-42-juges` — décision déléguée par Willy au head, « tranche et avançons », session
  principale, 2026-09-25 : correction reportée, pas traitée ici). Relevée par l'audit final de la
  Phase 42 (même famille que CR-01 côté agents, jamais corrigée côté scripts installés).

- **Écart D-08(b) non résolu sur le chemin `vf-dev-manager` → `vf-design-judge`** : la
  condition (b) de Samuel en ratifiant D-08 (« le digest du manager porte les interdits du
  lab ») est remplie côté `vf-design-manager` → `vf-design-judge` (nœud
  `fix-42-condition-samuel`, 2026-09-25), mais PAS sur le chemin `vf-dev-manager` →
  `vf-design-judge` (étage design d'une mission dev, mode `specs+implementation`) : c'est
  `vf-dev-manager` qui compose ce digest-là, et ce module relève de `plugin/dev-orchestrator/`,
  de la polarité de Samuel (D-12) — hors périmètre de tout commit de ce nœud. Détail :
  `42-05-SUMMARY.md` § Écart non résolu. À trancher à la revue code owner de Samuel.

- **Revue de fond des grilles de `quality-gate-client` et `content-clarity-judge`** :
  la correction du nœud `fix-42-juges` (2026-09-25) répare uniquement l'omission de citation du
  `CLAUDE.md` du lab comme source (T-42-07). Elle ne revisite PAS le contenu des rubriques /100
  elles-mêmes au regard du motif 3 de l'arbitrage D-08 (« tout ce qu'un juge vérifie vit dans sa
  grille ») : ni `quality-gate-client` ni `content-clarity-judge` ne portent aujourd'hui de
  critère RGPD EXPLICITE dans leur tableau de rubrique (contrairement à `growth-quality-judge`,
  critère 2 « Consentement / anti-spam / RGPD », éliminatoire) — la citation du `CLAUDE.md` comme
  source à lire ne garantit pas, à elle seule, qu'un manquement RGPD fasse baisser le score ou
  déclenche un éliminatoire. Revue de fond à mener séparément, hors périmètre de ce nœud.
