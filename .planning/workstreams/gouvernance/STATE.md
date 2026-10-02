---
gsd_state_version: 1.0
workstream: gouvernance
milestone: gouvernance-labs-v1.0
milestone_name: « le planning métier tenu par une machine »
current_phase: 45
current_phase_name: Moteur — hook central par rôle et gates d'écriture
status: "Phase 45 cadrée et planifiée (10 plans, plan-check frais PASSED), non exécutée"
created: 2026-09-23
last_updated: "2026-09-29T00:00:00.000Z"
last_activity: 2026-09-29
last_activity_desc: >-
  Cadrage et planification de la Phase 45 (mission vf-dev-manager-g45-20260929, branche
  gouvernance/phase-45-hook-central) : 45-CONTEXT.md (P45-D-01 à P45-D-21c, exigences GATE-01..15),
  45-SCOUTING/RESEARCH/PATTERNS/VALIDATION, 10 plans en 8 vagues ; plan-check frais PASSED au tour 6
  (4632c9b) après 5 révisions chirurgicales. Arbitrages Willy, AskUserQuestion session principale,
  2026-09-29 : Q1-Q6 et 13 décisions déléguées (reconfirmées après /clear), P45-D-21a, P45-D-14a.
stopped_at: >-
  Phase 45 planifiée, PR de planification ouverte (sans merge, sans release). Prochain geste :
  exécution de la Phase 45 (gsd-execute-phase 45 --ws gouvernance), vague 1 (45-01 ∥ 45-02).
progress:
  total_phases: 9
  completed_phases: 3
  total_plans: 28
  completed_plans: 18
  percent: 64
---

# Project State

## Current Position

Phase: 45 (Moteur — hook central par rôle et gates d'écriture) — cadrée et planifiée le 2026-09-29 (10 plans, 8 vagues, plan-check frais PASSED au tour 6 sur `4632c9b`), non exécutée ; PR de planification ouverte, sans merge. Phase 44 : exécutée (5/5 plans), vérifiée PASSED (18/18 MOTR-01..18, `44-VERIFICATION.md`), corrigée en 8 lots après revue et audit, CLOSE dans le ROADMAP le 2026-09-28 (PR vers main ouverte, non mergée). Phases 42 et 43 : exécutées, vérifiées et CLÔTURÉES dans le planning (PR #108 et PR #111 mergées sur main le 2026-09-27). Revue code owner de Samuel toujours en attente sur les deux PR (contournement D-02bis).
**Last Activity:** 2026-09-29
**Last Activity Description:** Cadrage et planification de la Phase 45 (mission `vf-dev-manager-g45-20260929`) — voir `last_activity_desc` en frontmatter. Précédent : clôture de la Phase 44 (mission `mgr-44-reprise`). Dernier lot : correction de CLASSE lot 8 (quick 260928-vk9, CORRECTION MINIMALE, aucun nouveau tour de juges, gsd-verifier PASSED), commit `0c284e3`.

Précédent : correction de CLASSE lot 5 (nœud `exec-44` rouvert, mission vf-coder `mgr-44-reprise`, quick task `260928-ol3`) : l'environnement « maîtrisé » du sous-processus détecteur (lot 4) était en réalité `dict(os.environ)` avec la seule surcharge de `GSD_HOME` — une copie intégrale du `PATH` hérité. Mesuré (attack probe direct, hors suite) : un `awk` factice en tête de PATH suffisait à faire écrire (exit 0) le moteur sur un lab GSD réel et à effacer le marqueur `gsd_state_version`. L'environnement est désormais construit DE ZÉRO (liste blanche `PATH_MAITRISE` + `GSD_HOME`, aucune autre variable héritée) ; `bash` résolu par `CANDIDATS_BASH` (deux chemins absolus fixes, validés par `lstat`), jamais `shutil.which` sur le PATH hérité. Correctifs voisins : `_jeton_journal` échappe aussi tout caractère non imprimable (NUL, contrôles C0/C1) ; un repli vide lève `ValueError` (jamais un jeton vide silencieux) ; « détecteur absent »/« détecteur non régulier » ont deux messages distincts ; `ecrire_si_different` lit par `O_NOFOLLOW`. Point explicitement NON retenu (avec preuve) : gater le code 3 sur une sortie stderr non vide — un `.planning/workstreams/` vide en produit légitimement. 233→270 OK/0 KO sur test-recalc-planning.sh, 8 suites sœurs vertes et non modifiées, `detect-gsd-engine.sh`/`workstream-policy.sh` octet pour octet inchangés depuis `424cb23`. Le dispatch `gsd-executor` isolé n'a pas été retenté (expérience du lot 4 déjà consignée) ; un seul commit (correctifs trop imbriqués pour un découpage fix/test/docs). Vérifié PASSED 11/11 par `gsd-verifier`. Commit `9fe4a42`.

Précédent : correction de CLASSE lot 4 (quick task `260928-mgu`) : `detection_gsd()` appelle le VRAI `detect-gsd-engine.sh` en sous-processus au lieu de réimplémenter ses priorités en Python, fermant les trois divergences mesurées de la copie du lot 3. `_jeton_journal` passe à un encodage pourcent injectif. 180→233 OK/0 KO, 8 suites sœurs vertes, `gsd-verifier` PASSED 7/7. Commits `b63da53`/`2fbbd65`/`3d72452`.

Précédent : correction ciblée lot 3 (quick task `260928-ccz`) : dédoublonnage du journal comparé sur la valeur assainie des deux côtés (constat 1, revue — round-trip réel prouvé rouge/vert), refus « migration à examiner » de `detection_gsd()` indépendant de `GSD_HOME` sur le repli code 1 (constat 2, audit — combinaison socle+signal reproduite en Python pur, `detect-gsd-engine.sh` inchangé). 171→180 OK/0 KO sur test-recalc-planning.sh, 8 suites sœurs vertes et non modifiées, `gsd-verifier` PASSED 7/7. Commits `dab3f62`/`89270fa`/`22381c1`.

Précédent : correction ciblée lots 1+2 (quick task `260928-b4c`) : gardes F3/F4/F5, couverture des 8 marqueurs restants de `detection_gsd()`, scindage du code 2/3 du détecteur GSD (lot 2 L1), assainissement structurel du journal (lot 2 L2), corrections de doc (DOC-44-02/03, F6, Banc F1). 171 OK/0 KO sur test-recalc-planning.sh, 8 suites sœurs vertes et non modifiées, `gsd-verifier` PASSED 11/11. Commits `e4898a0`/`aa8420d`/`fda472a`.

## Progress

**Phases Complete:** 3 (Phase 42 : PR #108 mergée 2026-09-27 ; Phase 43 : PR #111 mergée 2026-09-27 — revue code owner de Samuel en attente sur les deux ; Phase 44 : close le 2026-09-28, PR vers main ouverte, non mergée).
**Current Plan:** aucun en cours — Phase 45 planifiée (45-01 à 45-10), exécution non commencée

## Session Continuity

**Stopped At:** Phase 45 cadrée et planifiée (plan-check frais PASSED, PR de planification ouverte, sans merge). Prochain geste : exécution de la Phase 45 (`gsd-execute-phase 45 --ws gouvernance`), vague 1.
**Resume File (Phase 45) :** `.planning/missions/2026-09-29-gouvernance-45.md`
**Resume File:** `.planning/missions/2026-09-27-gouvernance-44.md`

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260928-b4c | Correction ciblée lots 1+2, Phase 44 : gardes F3/F4/F5, couverture F2, scindage code 2/3 du détecteur GSD, assainissement du journal, corrections doc | 2026-09-28 | fda472a | passed | [260928-b4c-correction-cibl-e-lots-1-2-phase-44-gard](./quick/260928-b4c-correction-cibl-e-lots-1-2-phase-44-gard/) |
| 260928-ccz | Correction ciblée lot 3, Phase 44 : dédoublonnage du journal sur valeur assainie (constat 1, revue), refus code 1 sur socle+signal indépendant de GSD_HOME (constat 2, audit) | 2026-09-28 | 22381c1 | passed | [260928-ccz-correction-cibl-e-lot-3-phase-44-d-doubl](./quick/260928-ccz-correction-cibl-e-lot-3-phase-44-d-doubl/) |
| 260928-mgu | Correction de CLASSE lot 4, Phase 44 : detection_gsd() appelle le vrai détecteur sous environnement maîtrisé (plus de réimplémentation Python), encodage injectif du journal | 2026-09-28 | 3d72452 | passed | [260928-mgu-correction-de-classe-lot-4-detection-gsd](./quick/260928-mgu-correction-de-classe-lot-4-detection-gsd/) |
| 260928-ol3 | Correction de CLASSE lot 5, Phase 44 : environnement du sous-processus détecteur construit de zéro (jamais dict(os.environ)), bash résolu par une liste fixe de chemins absolus, alphabet du journal étendu (NUL/C0/C1), messages distincts, O_NOFOLLOW | 2026-09-28 | 9fe4a42 | passed | [260928-ol3-correction-de-classe-lot-5-environnement-maitrise](./quick/260928-ol3-correction-de-classe-lot-5-environnement-maitrise/) |
| 260928-q6h | Correction ciblée lot 6, Phase 44 (audit HIGH) : garde de fidélité d'énumération des compartiments de workstream côté appelant, AVANT tout appel au détecteur (detect-gsd-engine.sh/workstream-policy.sh inchangés, P44-D-01b) ; correctifs de revue WR-02/WR-03/IN-01/IN-02 | 2026-09-28 | 770c35b | passed | [260928-q6h-ferme-le-masquage-de-compartiment-de-wor](./quick/260928-q6h-ferme-le-masquage-de-compartiment-de-wor/) |
| 260928-s53 | Correction de CLASSE lot 7, Phase 44 : garde de lecture du détecteur — fidélité par EXÉCUTION de vf_ws_enumerate + lisibilité réelle de chaque compartiment/STATE.md, ferme la classe permissions dégradées (000/600/400) plus large que le lot 6 (detect-gsd-engine.sh/workstream-policy.sh inchangés, P44-D-01b) | 2026-09-28 | 4b666e9 | passed | [260928-s53-correction-de-classe-lot-7-garde-de-lect](./quick/260928-s53-correction-de-classe-lot-7-garde-de-lect/) |
| 260928-vk9 | Correction de CLASSE lot 8, Phase 44 (CORRECTION MINIMALE, dernier lot, aucun nouveau tour de juges) : lien symbolique cassé traité comme absent (`os.path.isfile`, mirroir de `[ -f ]`), `_ouvrable` non bloquante sur FIFO (O_NONBLOCK + fstat), correction de prose (detect-gsd-engine.sh/workstream-policy.sh inchangés, P44-D-01b) | 2026-09-28 | 0c284e3 | passed | [260928-vk9-correction-de-classe-lot-8-garde-de-lect](./quick/260928-vk9-correction-de-classe-lot-8-garde-de-lect/) |
| 260928-uu0 | Correction de portabilité GNU/BSD, Phase 44 (reprise mgr-44-reprise, nœud livraison-44) : les 3 sites `stat -f "%Lp" ... \|\| stat -c "%a" ...` (R14, MUT-CHMOD, MUT-CHMOD-JOURNAL), source du KO `R14 permissions` sur le runner CI Linux, remplacés par `mode_octal()` (lecture via `os.stat().st_mode` par `$PYBIN`, une seule sémantique GNU/BSD) ; reste de la suite balayé, aucune autre correction nécessaire (recalc-planning.sh/detect-gsd-engine.sh/workstream-policy.sh inchangés) | 2026-09-28 | ad0a0fc | passed | [260928-uu0-corrige-la-portabilit-gnu-bsd-de-test-re](./quick/260928-uu0-corrige-la-portabilit-gnu-bsd-de-test-re/) |

## Note pour Willy (2026-09-23, partition D-02)

Ce compartiment reçoit le jalon `gouvernance-labs-v1.0` (Phases 42-50) — voir
`.planning/workstreams/gouvernance/ROADMAP.md` et `REQUIREMENTS.md` (`FABR-01..05`). Le contenu déjà
planifié de la Phase 42 (6 plans + `42-CONTEXT.md`/`42-RESEARCH.md`/`42-PATTERNS.md`/`42-VALIDATION.md`)
a été déplacé tel quel depuis la racine, rien réécrit. Détail complet de la partition :
`.planning/missions/2026-09-23-partition-planning-d02.md`.

**À toi (2026-10-02)** : les plans 41-07 à 41-13 de la Phase 41 (chaîne des mesures de la protection serveur, `fiabilite`) te sont confiés, hors clôture de `fiabilite-v1.0` (arbitrage Samuel, AskUserQuestion session principale, 2026-10-02 : « Toute la chaîne à Willy », après « Les confier à Willy » pour 41-07 à 41-09) — voir `.planning/workstreams/fiabilite/ROADMAP.md` § Phase 41.

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
